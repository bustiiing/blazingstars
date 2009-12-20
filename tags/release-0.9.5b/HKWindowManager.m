//
//  HKWindowManager.m
//  PokerHK
//
//  Created by Steven Hamblin on 09/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "HKWindowManager.h"

static NSRect FlippedScreenBounds(NSRect bounds)
{
    float screenHeight = NSMaxY([[[NSScreen screens] objectAtIndex:0] frame]);
    bounds.origin.y = screenHeight - NSMaxY(bounds);
	NSLog(@"BOUNDS: %f",bounds.origin.y);
    return bounds;
}

void axObserverCallback(AXObserverRef observer, 
						AXUIElementRef elementRef, 
						CFStringRef notification, 
						void *refcon);	

// I don't like doing this this way, but the refcon data crashes when I try to send a msg to it.
HKWindowManager *wm = NULL;

@implementation HKWindowManager

@synthesize activated;
#pragma mark Initialization

+(void)initialize {
	NSLog(@"Registering defaults.");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
	[appDefaults setObject:[NSNumber numberWithFloat:1.0] forKey:@"tournamentCloseLobbyDelayKey"];
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"hsWarningKey"];
    [defaults registerDefaults:appDefaults];
}

-(void)awakeFromNib
{
	wm = self;
	
	// Set up window dictionary
	windowDict = [[NSMutableDictionary alloc] init];
	
	NSWorkspace * ws = [NSWorkspace sharedWorkspace];
	NSArray *pids = [ws launchedApplications];
	
	for (id app in pids) {
		if ([[app objectForKey:@"NSApplicationName"] isEqualToString: @"PokerStars"]) {
			pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		}
	}
	
	NSLog(@"Registering windowobserver for HKWindowManager.");
	AXObserverCreate(pokerstarsPID, axObserverCallback, &observer);
	appref = AXUIElementCreateApplication(pokerstarsPID);
	
	AXObserverAddNotification(observer, appref, kAXWindowCreatedNotification, (void *)self);
	AXObserverAddNotification(observer, appref, kAXWindowResizedNotification, (void *)self);	
	AXObserverAddNotification(observer, appref, kAXApplicationActivatedNotification, (void *)self);	
	AXObserverAddNotification(observer, appref, kAXApplicationDeactivatedNotification, (void *)self);	
	CFRunLoopAddSource ([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
	
	NSLog(@"Window manager getting window list for windowDict.");
	NSArray *children;
	AXUIElementCopyAttributeValues(appref, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);
	
	NSString *name; 
	NSString *role;
	
	for (id child in children) {
		AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXTitleAttribute, (CFTypeRef *)&name);
		AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXRoleAttribute, (CFTypeRef *)&role);
		NSLog(@"Role: %@", role);
		if ([self windowIsTable:(AXUIElementRef) child] == HKHoldemCashTable || [self windowIsTable:(AXUIElementRef)child] == HKTournamentTable) {
			id *size; CGSize sizeVal;			
			AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXSizeAttribute,(CFTypeRef *)&size);
			AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal);
//			[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:[NSValue valueWithPointer:child]];
			[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:name];			
			AXObserverAddNotification(observer, (AXUIElementRef)child, kAXUIElementDestroyedNotification, (void *)self);			
		}
	}
	NSLog(@"windowDict: %@",windowDict);

	
}

#pragma mark Window Interaction
-(void)debugWindow:(NSRect)windowRect
{
	NSWindow *window = [[NSWindow alloc] initWithContentRect:FlippedScreenBounds(windowRect) styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:YES];
	[window setOpaque:NO];
	[window setAlphaValue:0.20];
	[window setBackgroundColor:[NSColor yellowColor]];
	[window setLevel:NSStatusWindowLevel];
	[window setReleasedWhenClosed:YES];
	[window orderFront:nil];
	
	[NSThread sleepForTimeInterval:0.5];
	[window close];	
}

-(void)clickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width
{
	AXUIElementRef mainWindow = [self getMainWindow];
	NSRect windowRect = [self getWindowBounds:mainWindow];
	
	windowRect.origin.x = windowRect.size.width * xsize + windowRect.origin.x;
	windowRect.origin.y = windowRect.size.height * ysize + windowRect.origin.y;
	
	windowRect.size.width = windowRect.size.width * width;
	windowRect.size.height = windowRect.size.height * height;		
	
	CGPoint eventCenter = {
		.x = (windowRect.origin.x + (windowRect.size.width / 2)),
		.y = (windowRect.origin.y + (windowRect.size.height / 2))
	};
	
#ifdef HKDEBUG
	[self debugWindow:windowRect];
#endif

	NSLog(@"\nAttempting mouse click at: x=%g y=%g.",eventCenter.x,eventCenter.y);
	
	CGAssociateMouseAndMouseCursorPosition(false);
	
	CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, eventCenter, kCGMouseButtonLeft);
	
	// Cancel any of the modifier keys - this caused me a day of bug-hunting!
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGHIDEventTap,mouseEvent);
	
	mouseEvent = CGEventCreateMouseEvent(NULL,kCGEventLeftMouseUp,eventCenter,kCGMouseButtonLeft);
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGHIDEventTap,mouseEvent);
	
	CGAssociateMouseAndMouseCursorPosition(true);	
}

-(NSPoint)getClickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width
{
	
	AXUIElementRef mainWindow = [self getMainWindow];
	
	NSRect windowRect = [self getWindowBounds:mainWindow];
	
	windowRect.origin.x = windowRect.size.width * xsize + windowRect.origin.x;
	windowRect.origin.y = windowRect.size.height * ysize + windowRect.origin.y;
	
	windowRect.size.width = windowRect.size.width * width;
	windowRect.size.height = windowRect.size.height * height;		
	
	CGPoint eventCenter = {
		.x = (windowRect.origin.x + (windowRect.size.width / 2)),
		.y = (windowRect.origin.y + (windowRect.size.height / 2))
	};
	
	NSLog(@"inClick:  x=%f,y=%f",eventCenter.x,eventCenter.y);
	return NSPointFromCGPoint(eventCenter);
}


#pragma mark Windows is table.

// Helper function:  is this window a poker *table* as opposed to lobby or other window?  Pass in an elementRef to get the answer from the title.
-(int)windowIsTable:(AXUIElementRef)windowRef
{
	NSString *title;
	AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef *)&title);	
	if ([title length] > 0) {
		NSLog(@"Title: %@",title);
		if ([title rangeOfString:@"Tournament"].location != NSNotFound && [title rangeOfString:@"Table"].location != NSNotFound) {
			return HKTournamentTable;
		} else if ([title rangeOfString:@"Tournament"].location != NSNotFound && [title rangeOfString:@"Table"].location != NSNotFound) {
			return HKTournamentLobby;
		} else if ([title rangeOfString:@"Tournament"].location != NSNotFound) {
			return HKTournamentPopup;
		} else if ([title rangeOfString:@"Hold'em"].location != NSNotFound) {
			return HKHoldemCashTable;
		} else {
			return HKNotTable;
		}		
	} else {
		return HKNotTable;
	}	
}

-(int)windowIsTableAtOpening:(AXUIElementRef)windowRef
{
	NSString *title;
	AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef *)&title);	
	if ([title length] > 0) {
		NSLog(@"Title: %@",title);
		if ([title rangeOfString:@"Table"].location != NSNotFound && [title rangeOfString:@"Options"].location == NSNotFound) {
			NSArray *children;
			AXUIElementCopyAttributeValues(windowRef, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);
			BOOL isPopup = NO; NSString *name;
			
			for (id child in children) {
				AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXRoleAttribute, (CFTypeRef *)&name);
				if ([name isEqual:@"AXButton"]) {
					NSString *buttonName;
					AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXTitleAttribute,(CFTypeRef *)&buttonName);
					if ([buttonName isEqual:@"OK"]) {						
						isPopup = YES;
					}
				}
			}
			if (isPopup == YES) {
				return HKTablePopup;
			} else {
				return HKGeneralTable;
			}	
		} else if ([title rangeOfString:@"Tournament Registration"].location != NSNotFound) {
			return HKTournamentRegistration;
		} 
	} else {
		return HKNotTable;
	}	
	return HKNotTable;
}

-(BOOL)pokerWindowIsActive
{
	int retVal = [self windowIsTable:[self getMainWindow]];
	if (retVal == HKTournamentTable || retVal == HKHoldemCashTable) {
		return YES;
	} else {
		return NO;
	}
}

-(AXUIElementRef)getMainWindow
{
	AXUIElementRef mainWindow;
	NSArray *children;
	AXError axErr = AXUIElementCopyAttributeValues(appref, kAXChildrenAttribute,0,100, (CFArrayRef *)&children);
	if (axErr != kAXErrorSuccess) {
		NSLog(@"Retrieving children failed. %d", axErr);
	}
	
	NSEnumerator * enumerator = [children objectEnumerator];
	AXUIElementRef child;
	while ((child = (AXUIElementRef)[enumerator nextObject])) {
		NSString *value;
		AXUIElementCopyAttributeValue(child,kAXMainAttribute,(CFTypeRef *)&value);	
		
		// Check to see if this is main window we're looking at.  It's here that we'll send the mouse events.
		if ([value intValue] == 1) {
			NSString *title;
			AXUIElementCopyAttributeValue(child,kAXTitleAttribute,(CFTypeRef *)&title);
			mainWindow = child;
		}
	}
	return mainWindow;
}

-(NSArray *)getAllPokerTables
{
	NSMutableArray *pokerTables = [[NSMutableArray alloc] init];
	NSArray *children;
	AXError axErr = AXUIElementCopyAttributeValues(appref, kAXChildrenAttribute,0,100, (CFArrayRef *)&children);
	if (axErr != kAXErrorSuccess) {
		NSLog(@"Retrieving children failed. %d", axErr);
	}
	
	NSEnumerator * enumerator = [children objectEnumerator];
	AXUIElementRef child;
	while ((child = (AXUIElementRef)[enumerator nextObject])) {
		// Check to see if this is a poker table.
		int tableType = [self windowIsTable:child];
		if (tableType == HKHoldemCashTable || tableType == HKTournamentTable) {
			[pokerTables addObject:[NSValue valueWithPointer:child]];
		}
	}	
	return pokerTables;
}

-(NSRect)getWindowBounds:(AXUIElementRef)windowRef
{
	id *size;
	AXError axErr = AXUIElementCopyAttributeValue(windowRef,kAXSizeAttribute,(CFTypeRef *)&size);
	CGSize sizeVal;
	
	if (AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal)) {
		NSLog(@"\nSize: w=%g h=%g",sizeVal.width,sizeVal.height);
	} 
	
	id *position;
	axErr = AXUIElementCopyAttributeValue(windowRef,kAXPositionAttribute,(CFTypeRef *)&position);
	if (axErr != kAXErrorSuccess) {
		NSLog(@"\nCould not retrieve mainWindow position. %d",axErr);
	}
	
	CGPoint corner;
	if (AXValueGetValue((AXValueRef)position, kAXValueCGPointType, &corner)) {
		NSLog(@"\nPosition: x=%g y=%g",corner.x,corner.y);
	} else {
		NSLog(@"\nCould not retrieve point!");
	}
	
	// Place a window over the button for visual aid..
	//	NSWindow *window;
	NSRect windowRect;
	
	windowRect.origin = *(NSPoint *)&corner;
	windowRect.size = *(NSSize *)&sizeVal;
	
	return windowRect;
}

-(NSRect)getPotBounds:(AXUIElementRef)windowRef
{
	NSRect windowRect = [self getWindowBounds:windowRef];
	
	NSRect boundBox = NSMakeRect([[themeController param:@"potBoxOriginX"] floatValue],
								 [[themeController param:@"potBoxOriginY"] floatValue],
								 [[themeController param:@"potBoxWidth"] floatValue],
								 [[themeController param:@"potBoxHeight"] floatValue]);
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:(windowRect.size.width / [[themeController param:@"defaultWindowWidth"] floatValue]) 
					yBy: ((windowRect.size.height) / [[themeController param:@"defaultWindowHeight"] floatValue])];
	[transform concat];
	
	boundBox.size = [transform transformSize:boundBox.size];
	boundBox.origin = [transform transformPoint:boundBox.origin];

	
	NSSize tempSize = windowRect.size;
	
	// Have to set the origin by hand.  
	boundBox.origin.y = [[themeController param:@"intercept"] floatValue] + ([[themeController param:@"coefficient"] floatValue] * tempSize.height) + windowRect.origin.y;
	boundBox.origin.x += windowRect.origin.x;
	return boundBox;
}

-(NSArray *)getGameParameters
{
	NSLog(@"Trying to get blind size.");
	
	AXUIElementRef mainWindow = [self getMainWindow];
	NSString *title; 
	AXUIElementCopyAttributeValue(mainWindow,kAXTitleAttribute,(CFTypeRef *)&title);
	
	NSString *smallBlind, *bigBlind, *gameType;
	
	if ([title rangeOfString:@"Tournament"].location == NSNotFound) {		
		smallBlind = [[title componentsSeparatedByString:@"/"] objectAtIndex:0];
		bigBlind = [[title componentsSeparatedByString:@"/"] objectAtIndex:1];
		
		NSMutableCharacterSet *money = [[NSMutableCharacterSet alloc] init];
		[money formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
		[money formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
		[money formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"$-'"]];
		
		smallBlind = [smallBlind stringByTrimmingCharactersInSet:money];
		bigBlind = [bigBlind stringByTrimmingCharactersInSet:money];
		NSLog(@"Small blind: %@  Big blind: %@",smallBlind,bigBlind);	
		
		gameType = [[[title componentsSeparatedByString:@"-"] objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSLog(@"Game type: %@", gameType);
		
	} else {
		NSArray *temp = [[[title componentsSeparatedByString:@"/"] objectAtIndex:0] componentsSeparatedByString:@" "];
		smallBlind = [temp objectAtIndex:[temp count]-1];
		temp = [[[title componentsSeparatedByString:@"/"] objectAtIndex:1] componentsSeparatedByString:@" "];
		bigBlind = [temp objectAtIndex:0];
		NSMutableCharacterSet *money = [[NSMutableCharacterSet alloc] init];
		[money formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
		[money formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
		[money formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"$-'"]];
		
		smallBlind = [smallBlind stringByTrimmingCharactersInSet:money];
		bigBlind = [bigBlind stringByTrimmingCharactersInSet:money];
		NSLog(@"Small blind: %@  Big blind: %@",smallBlind,bigBlind);	
		
		gameType = @"Tournament";
		NSLog(@"Game type: %@", gameType);
		
	}
	
	return [NSArray arrayWithObjects:[NSNumber numberWithFloat:[smallBlind floatValue]],
			[NSNumber numberWithFloat:[bigBlind floatValue]],gameType,nil];
}


#pragma mark notificationHandlers

-(void)windowDidOpen:(AXUIElementRef)elementRef
{
	NSUserDefaults *sdc = [NSUserDefaults standardUserDefaults];
	if ([sdc floatForKey:@"tournamentCloseLobbyDelayKey"]) {
		NSLog(@"Delay: %f",[sdc floatForKey:@"tournamentCloseLobbyDelayKey"]);
		[NSThread sleepForTimeInterval:[sdc floatForKey:@"tournamentCloseLobbyDelayKey"]];
	} else {
		NSLog(@"Key not registered.");
		[NSThread sleepForTimeInterval:0.5];
	}
	
	if ([self windowIsTableAtOpening:elementRef] == HKGeneralTable) {
		NSString *role; NSString *title;
		AXUIElementCopyAttributeValue(elementRef,kAXRoleAttribute,(CFTypeRef*)&role);
		AXUIElementCopyAttributeValue(elementRef,kAXTitleAttribute,(CFTypeRef*)&title);		
		NSLog(@"Role: %@", role);		
		
		id *size; CGSize sizeVal;			
		AXUIElementCopyAttributeValue(elementRef,kAXSizeAttribute,(CFTypeRef *)&size);
		AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal);
//		[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:[NSValue valueWithPointer:elementRef]];
		[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:title];		
		AXObserverAddNotification(observer,elementRef, kAXUIElementDestroyedNotification, (void *)self);			
		NSLog(@"windowDict is now: %@",windowDict);
		
		// If the window is a tournament window, we need to check if we need to close the lobby.
		if ([sdc boolForKey:@"tournamentCloseLobbyKey"]) {
			NSLog(@"Closing lobby!");
			// Check to see if this is a tournament table.
			if ([title rangeOfString:@"Tournament"].location != NSNotFound && [title rangeOfString:@"Table"].location != NSNotFound) {	
				NSLog(@"This is a tournament table!");
				
				NSRange tourneyRange,tableRange,tnumRange;
				tourneyRange = [title rangeOfString:@"Tournament"];
				tableRange = [title rangeOfString:@"Table"];
				float start = tourneyRange.location + tourneyRange.length;  float len = tableRange.location-start;
				tnumRange = NSMakeRange(start,len);
				NSString *tnum = [title substringWithRange:tnumRange];
				NSLog(@"tnum: %@",tnum);

				// Now need to scan all the windows to find the lobby.  
				NSArray *children;
				AXUIElementCopyAttributeValues(appref, kAXChildrenAttribute,0,100, (CFArrayRef *)&children);
				
				NSEnumerator * enumerator = [children objectEnumerator];
				AXUIElementRef child;  NSString *childTitle;
				AXUIElementRef lobby;
				while ((child = (AXUIElementRef)[enumerator nextObject])) {
					// Check to see if this is the lobby.
					AXError err = AXUIElementCopyAttributeValue(child,kAXTitleAttribute,(CFTypeRef*)&childTitle);
					if (err == kAXErrorSuccess) {
						if ([childTitle rangeOfString:@"Tournament"].location != NSNotFound && [childTitle rangeOfString:@"Lobby"].location != NSNotFound) {
							NSLog(@"Found lobby! : %@",childTitle);
							lobby = child;
						}						
					}
				}
				// Raise the lobby and close it.
				AXUIElementPerformAction(lobby, kAXRaiseAction);
				// Cycle through the children, find the close button, and close the window.
				AXUIElementCopyAttributeValues(lobby,kAXChildrenAttribute,0,100, (CFArrayRef *)&children);
				enumerator = [children objectEnumerator];
				NSString *role,*subrole; AXError roleErr,subroleErr;
				while ((child = (AXUIElementRef)[enumerator nextObject])) {
					roleErr = AXUIElementCopyAttributeValue(child,kAXRoleAttribute,(CFTypeRef*)&role);
					if (roleErr == kAXErrorSuccess) {
						subroleErr = AXUIElementCopyAttributeValue(child,kAXSubroleAttribute,(CFTypeRef*)&subrole);
						if (subroleErr == kAXErrorSuccess) {
							NSLog(@"Role: %@ subrole: %@",role,subrole);
							if ([role rangeOfString:@"AXButton"].location != NSNotFound && [subrole rangeOfString:@"AXCloseButton"].location != NSNotFound) {
								NSLog(@"In the close button!");
								AXUIElementPerformAction(child, kAXPressAction);
								break;
							}
						}
					}
				}
			}
		}
		
	} else if ([self windowIsTableAtOpening:elementRef] == HKTournamentRegistration) {
		if ([sdc boolForKey:@"tournamentRegistrationPopupKey"])
		{
			NSLog(@"In closeTournamentWindow");
			NSString *name;
			AXUIElementCopyAttributeValue(elementRef, kAXTitleAttribute, (CFTypeRef *)&name);
			NSLog(@"Title: %@",name);
			
			if ([name isEqual:@"Tournament Registration"]) {
				NSArray *children;
				AXUIElementCopyAttributeValues(elementRef, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);
				AXUIElementRef OKButton = NULL;
				while (OKButton == NULL) {
					for (id child in children) {
						AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXRoleAttribute, (CFTypeRef *)&name);
						if ([name isEqual:@"AXRadioButton"]) {
							AXUIElementPerformAction((AXUIElementRef)child,kAXPressAction);
						} else if ([name isEqual:@"AXCheckBox"] && [sdc boolForKey:@"registerForIdenticalKey"]) {
							AXUIElementPerformAction((AXUIElementRef)child,kAXPressAction);
						} else if ([name isEqual:@"AXButton"]) {
							NSLog(@"In button.");
							NSString *buttonName;
							AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXTitleAttribute,(CFTypeRef *)&buttonName);
							if ([buttonName isEqual:@"OK"]) {
								NSLog(@"Saving button.");
								OKButton = (AXUIElementRef) child;
							}
						}
						NSLog(@"Child role: %@", name );						
					}
				}
				// Necessary because the window controls don't seem to populate fast enough - the button won't get pressed.
				[NSThread sleepForTimeInterval:0.3];
				NSLog(@"Button: %@", OKButton);
				AXError err = AXUIElementPerformAction(OKButton, kAXPressAction);
				NSLog(@"Error: %d",err);			
			}
		}
	} else if ([self windowIsTableAtOpening:elementRef] == HKTablePopup) {
		NSArray *children; NSString *name; 
		NSMutableArray *windowsToClose = [[NSMutableArray alloc] init];
		
		// Build list of Table popups.
		AXUIElementCopyAttributeValues(appref,kAXChildrenAttribute,0,500,(CFArrayRef *)&children);
		for (id child in children) {
			if ([self windowIsTableAtOpening:(AXUIElementRef)	child] == HKTablePopup) {
				[windowsToClose addObject:child];
			}
		}

		// Go through each table popup, try to press the close button.  This is *extremely* inelegant, but I'm having trouble coming up
		// with another way to handle this right now.
		NSLog(@"Windows to close: %@",windowsToClose);
		for (id element in windowsToClose) {
			AXUIElementCopyAttributeValues((AXUIElementRef) element, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);
			AXUIElementRef OKButton = NULL;
			while (OKButton == NULL) {
				for (id child in children) {
					AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXRoleAttribute, (CFTypeRef *)&name);
					if ([name isEqual:@"AXButton"]) {
						NSLog(@"In button.");
						NSString *buttonName;
						AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXTitleAttribute,(CFTypeRef *)&buttonName);
						if ([buttonName isEqual:@"OK"]) {
							NSLog(@"Saving window.");
							OKButton = (AXUIElementRef) child;
						}
					}
				}
			}
			[NSThread sleepForTimeInterval:0.2];
			NSLog(@"Button: %@", OKButton);
			AXError err = AXUIElementPerformAction(OKButton, kAXPressAction);
			NSLog(@"Error: %d",err);			
		}
		
	}		
	return;

}

-(void)windowDidResize:(AXUIElementRef)elementRef
{
	NSString *title;
	NSString *role;
	AXUIElementCopyAttributeValue(elementRef,kAXTitleAttribute,(CFTypeRef *)&title);
	NSLog(@"Title: %@", title);
	
	AXUIElementCopyAttributeValue(elementRef,kAXRoleAttribute,(CFTypeRef*)&role);
	NSLog(@"Role: %@", role);
	
	
	NSSize oldsize;
//	oldsize = NSSizeFromString([[windowDict objectForKey:[NSValue valueWithPointer:elementRef]] objectAtIndex:0]);
	oldsize = NSSizeFromString([[windowDict objectForKey:title] objectAtIndex:0]);	
	NSLog(@"Value: %@",NSStringFromSize(oldsize));
	
	
	id *size; CGSize sizeVal;			
	AXUIElementCopyAttributeValue(elementRef,kAXSizeAttribute,(CFTypeRef *)&size);
	AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal);
//	[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:[NSValue valueWithPointer:elementRef]];
	[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:title];	
	NSLog(@"Window resized: %@.",NSStringFromSize(NSSizeFromCGSize(sizeVal)));	
	NSLog(@"New aspect ratio: %f",sizeVal.width / sizeVal.height);
	NSLog(@"Old aspect ratio: %f",oldsize.width / oldsize.height);
	NSLog(@"Aspect ratio diff: %f",((sizeVal.width / sizeVal.height) / (oldsize.width / oldsize.height)));
	NSLog(@"Window dict: %@",windowDict);
}

-(void)windowDidClose:(AXUIElementRef)elementRef
{
	[windowDict removeAllObjects];
	NSArray *children;
	AXUIElementCopyAttributeValues(appref, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);
	
	NSString *name; 
	
	for (id child in children) {
		AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXTitleAttribute, (CFTypeRef *)&name);
		if ([self windowIsTable:(AXUIElementRef) child] == HKHoldemCashTable || [self windowIsTable:(AXUIElementRef)child] == HKTournamentTable) {
			id *size; CGSize sizeVal;			
			AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXSizeAttribute,(CFTypeRef *)&size);
			AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal);
//			[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:[NSValue valueWithPointer:child]];
			[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),nil] forKey:name];			
			AXObserverAddNotification(observer, (AXUIElementRef)child, kAXUIElementDestroyedNotification, (void *)self);			
		}
	}
	NSLog(@"windowDict: %@",windowDict);
	
}

/*-(void)applicationDidActivate
{
	if ([dispatchController toggled] == NO) {
		[dispatchController registerAllHotKeys];		
	}
	[self setActivated:YES];
}

-(void)applicationDidDeactivate
{
	if ([dispatchController toggled] == NO) {
		[dispatchController unregisterAllHotKeys];		
	}
	[self setActivated:NO];
}*/

-(void)applicationDidActivate
{
	if ([self activated] == NO) {
		[self setActivated:YES];
		[dispatchController toggleAllHotKeys];		
	} else {
		NSLog(@"We're already activated!");
	}
	
}

-(void)applicationDidDeactivate
{
	if ([self activated] == YES) {
		[self setActivated:NO];
		[dispatchController toggleAllHotKeys];		
	} else {
		NSLog(@"We're already deactivated!");
	}
}


@end


void axObserverCallback(AXObserverRef observer, 
                               AXUIElementRef elementRef, 
                               CFStringRef notification, 
                               void *refcon) 
{
	if (CFStringCompare(notification,kAXWindowCreatedNotification,0) == 0) {
		[wm windowDidOpen:elementRef];
	} else if (CFStringCompare(notification,kAXWindowResizedNotification,0) == 0) {
		[wm windowDidResize:elementRef];
	} else if (CFStringCompare(notification,kAXApplicationActivatedNotification,0) == 0) {
		// For some reason, this and the next notification get called multiple times.  
		NSLog(@"The PokerStars client was activated!");
		[wm applicationDidActivate];
	} else if (CFStringCompare(notification,kAXApplicationDeactivatedNotification,0) == 0) {
		NSLog(@"The PokerStars client was deactivated!");
		[wm applicationDidDeactivate];
	} else if (CFStringCompare(notification,kAXUIElementDestroyedNotification,0) == 0) {
		[wm windowDidClose:elementRef];
	}
}

