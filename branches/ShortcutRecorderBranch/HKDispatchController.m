//
//  HKDispatchController.m
//  PokerHK
//
//  Created by Steven Hamblin on 31/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "HKDispatchController.h"
#import "PrefsWindowController.h"
#import "HKScreenScraper.h"
#import <Carbon/Carbon.h>
#import <AppKit/NSAccessibility.h>

EventHotKeyRef	gHotKeyRef;
EventHotKeyID	gHotKeyID;
EventHandlerUPP	gAppHotKeyFunction;

// Forwards
pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData);

pascal OSStatus mouseEventHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData);

void axHotKeyObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon);	

typedef struct
	{
		// Where to add window information
		NSMutableArray * outputArray;
		// Tracks the index of the window when first inserted
		// so that we can always request that the windows be drawn in order.
		int order;
	} WindowListApplierData;

NSString *kAppNameKey = @"applicationName";    // Application Name & PID
NSString *kWindowOriginKey = @"windowOrigin";    // Window Origin as a string
NSString *kWindowSizeKey = @"windowSize";        // Window Size as a string
NSString *kWindowIDKey = @"windowID";            // Window ID
NSString *kWindowLevelKey = @"windowLevel";    // Window Level
NSString *kWindowOrderKey = @"windowOrder";    // The overall front-to-back ordering of the windows as returned by the window server
NSString *kWindowNameKey = @"windowName";

void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (NSDictionary*)inputDictionary;
    WindowListApplierData *data = (WindowListApplierData*)context;
    
    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
        
        // Grab the application name, but since it's optional so we need to check before we can use it.
        NSString *applicationName = [entry objectForKey:(id)kCGWindowOwnerName];
        if(applicationName != NULL)
        {
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, [entry objectForKey:(id)kCGWindowOwnerPID]];
            [outputEntry setObject:nameAndPID forKey:kAppNameKey];
        }
        else
        {
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", [entry objectForKey:(id)kCGWindowOwnerPID]];
            [outputEntry setObject:nameAndPID forKey:kAppNameKey];
        }
			
        // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as strings
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
        NSString *originString = [NSString stringWithFormat:@"%.0f/%.0f", bounds.origin.x, bounds.origin.y];
        [outputEntry setObject:originString forKey:kWindowOriginKey];
        NSString *sizeString = [NSString stringWithFormat:@"%.0f*%.0f", bounds.size.width, bounds.size.height];
        [outputEntry setObject:sizeString forKey:kWindowSizeKey];
        
        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        [outputEntry setObject:[entry objectForKey:(id)kCGWindowNumber] forKey:kWindowIDKey];
        [outputEntry setObject:[entry objectForKey:(id)kCGWindowLayer] forKey:kWindowLevelKey];
        
		NSString *windowName = [entry objectForKey:(id)kCGWindowName];
		if (windowName != NULL) {
			[outputEntry setObject:windowName forKey:kWindowNameKey];
		}
        // Finally, we are passed the windows in order from front to back by the window server
        // Should the user sort the window list we want to retain that order so that screen shots
        // look correct no matter what selection they make, or what order the items are in. We do this
        // by maintaining a window order key that we'll apply later.
        [outputEntry setObject:[NSNumber numberWithInt:data->order] forKey:kWindowOrderKey];
		
		// Look for PokerStars window:
		if ([applicationName isEqual:@"PokerStars"]) {
			data->order++;
			
			[data->outputArray addObject:outputEntry];
			
		}
    }
}



// Allow global access to the controller.
HKDispatchController *dc;
HKWindowManager *wm;

@implementation HKDispatchController

@synthesize keyMap;
@synthesize toggled;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[NSApp terminate:self];
}


#pragma mark Initialization

-(id)init
{
	if ((self = [super init])) {
		fieldMap = [[NSMutableDictionary alloc] init];
		keyMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"keyMap" ofType: @"plist"]];
		potBetAmounts = [[NSMutableDictionary alloc] init];
		amountToChange = 2.0;
		rounding = NO;
		autoBetRounding = NO;
		toggled = YES;
    }
	return self;
}

-(void)awakeFromNib 
{
	dc = self;
	wm = windowManager;

	// Register global event handler.
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	
	EventTypeSpec mouseEventType;
	mouseEventType.eventClass=kEventClassMouse;
	mouseEventType.eventKind=kEventMouseWheelMoved;

	InstallApplicationEventHandler(&hotKeyHandler,1,&eventType,(void *)self,&hotkeyEventHandlerRef);
	InstallEventHandler(GetEventMonitorTarget(),&mouseEventHandler,1,&mouseEventType,(void *)self,&mouseEventHandlerRef);
	
	NSArray *pids = [[NSWorkspace sharedWorkspace] launchedApplications];
	
	for (id app in pids) {
		if ([[app objectForKey:@"NSApplicationName"] isEqualToString: @"PokerStars"]) {
			pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		}
	}
	
	// Accessibility framework stuff now.
	appRef = AXUIElementCreateApplication(pokerstarsPID);
	
	if (!appRef) {
		NSLog(@"Could not get application ref.");
	}

	systemWideElement = AXUIElementCreateSystemWide();

	// Get the PrefsWindowController.
	prefsWindowController = [PrefsWindowController sharedPrefsWindowController];
}

-(void)setPotBetAmount:(float)amount forTag:(int)tag
{
	[potBetAmounts setObject:[NSNumber numberWithFloat:amount] forKey:[NSNumber numberWithInt:tag]];
	NSLog(@"Pot bet amounts now: %@",potBetAmounts);
}

-(void)turnOnRounding:(BOOL)round
{
	NSLog(@"Setting rounding to: %@\n", (round ? @"YES" : @"NO"));
	rounding = round;
}

-(void)setRoundingAmount:(float)amount
{
	NSLog(@"Setting rounding amount to: %f\n",amount);
	roundingAmount = amount;
}

-(void)setRoundingType:(int)type
{
	NSLog(@"Setting rounding type to: %d\n",type);
	roundingType = type;
}

-(void)autoBetRounding:(BOOL)aBool
{
	NSLog(@"Setting autoBetRounding to: %@\n",(aBool ? @"YES" : @"NO"));
	autoBetRounding = aBool;
}

-(void)autoBetAllIn:(BOOL)aBool
{
	NSLog(@"Setting autoBetAllIn to:%@\n",(aBool ? @"YES" : @"NO"));
	autoBetAllIn = aBool;
}

#pragma mark Hot Key Registration

-(void)registerHotKeyForControl:(SRRecorderControl *)control withTag:(int)tag
{
	NSLog(@"In registering function for SRRC. Tag: %d  Combo: %@",tag,[control keyComboString]);
	
	if ([[fieldMap allKeys] containsObject:[NSValue valueWithPointer:control]] == YES) {
		[fieldMap removeObjectForKey:[NSValue valueWithPointer:control]];
//		UnregisterEventHotKey([[fieldMap objectForKey:[NSValue valueWithPointer:control]] pointerValue]);
		NSLog(@"Yes, we found it.  Unregistering.");		
	} 

	if ([control keyCombo].code != -1) {
		//gHotKeyID.signature='wwhk';
		// Note:  this is tag+1, because of the historical mismatch between the controls I've been using (legacy
		// from using the Google HotKey field.
		//gHotKeyID.id=tag;
		
		//	EventHotKeyRef hkref; 
		//	RegisterEventHotKey([control keyCombo].code, SRCocoaToCarbonFlags([control keyCombo].flags), gHotKeyID, 
		//						GetApplicationEventTarget(), 0, &hkref);
		[fieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:NULL],[NSNumber numberWithInt:tag],nil] forKey:[NSValue valueWithPointer:control]];
		//	UnregisterEventHotKey([[[fieldMap objectForKey:[NSValue valueWithPointer:control]] objectAtIndex:0] pointerValue]);	
	} else {
		NSLog(@"Didn't register null key.");
	}
	//NSLog(@"Fieldmap Length: %d -> %@",[[fieldMap allKeys] count],fieldMap);
}

-(void)unregisterAllHotKeys
{
	NSLog(@"Unregistering all hotkeys.");
	SRRecorderControl *sc;
	NSMutableDictionary *newFieldMap = [[NSMutableDictionary alloc] init];
	for (id key in fieldMap) {
		sc = [key pointerValue];
		int tag = [[[fieldMap objectForKey:key] objectAtIndex:1] intValue];

		if (tag != TOGGLETAG) {
			NSLog(@"Unregister combo: %@ withTag: %d",[sc keyComboString],[[[fieldMap objectForKey:key] objectAtIndex:1] intValue]);
			OSStatus errCode = UnregisterEventHotKey([[[fieldMap objectForKey:key] objectAtIndex:0] pointerValue]);
			[newFieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:NULL],[NSNumber numberWithInt:tag],nil] forKey:key];
			if (errCode != noErr) {
				NSLog(@"Failed to unregister hotkey! :-> %d",errCode);
			}
			
		}
	}
	fieldMap = [newFieldMap mutableCopy];
}

-(void)registerAllHotKeys
{
	NSLog(@"Registering all keys!");
	EventHotKeyRef hkref;
	NSMutableDictionary *newFieldMap = [[NSMutableDictionary alloc] init];
	for (id field in fieldMap) {
		int tag = [[[fieldMap objectForKey:field] objectAtIndex:1] intValue];
		SRRecorderControl *control = [field pointerValue];
		
		gHotKeyID.signature='wwhk';
		gHotKeyID.id=tag;
		
		NSLog(@"Tag: %d Keycombo: %@",tag,[control keyComboString]);
				
		OSStatus err = RegisterEventHotKey([control keyCombo].code, SRCocoaToCarbonFlags([control keyCombo].flags), gHotKeyID, 
							GetApplicationEventTarget(), 0, &hkref);

		if (err != noErr) {
			NSLog(@"Registration failed! %d",err);
		}
		
		[newFieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:hkref],[NSNumber numberWithInt:tag],nil] forKey:field];
	}
	NSLog(@"Length: %d -> %@",[[fieldMap allKeys] count],fieldMap);
	fieldMap = [newFieldMap mutableCopy];
}

-(void)toggleAllHotKeys
{
	NSLog(@"Toggling all hotkeys.");
	if (toggled == NO) {
		NSLog(@"Toggling off.");
		toggled = YES;
		if ([windowManager activated] == NO) {
			NSLog(@"unregistering!");
			[self unregisterAllHotKeys];			
		}
	} else if (toggled == YES) {
		NSLog(@"Toggling on.");
		toggled = NO;
		if ([windowManager activated] == YES) {
			NSLog(@"registering!");
			[self registerAllHotKeys];			
		}
	}
}

#pragma mark Hot Key Execution.

-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size
{
	// The prefix maps the button to the plist for the specified theme.  
	NSLog(@"Prefix: %@  Size: %@ X: %g Y: %g H: %g W: %g",prefix,size,
		[[themeController param:[prefix stringByAppendingString:@"OriginX"]] floatValue],
		[[themeController param:[prefix stringByAppendingString:@"OriginY"]] floatValue],
		[[themeController param:[size stringByAppendingString:@"ButtonHeight"]] floatValue],
		  [[themeController param:[size stringByAppendingString:@"ButtonWidth"]] floatValue]);
	
	[windowManager clickPointForXSize:[[themeController param:[prefix stringByAppendingString:@"OriginX"]] floatValue]
					andYSize:[[themeController param:[prefix stringByAppendingString:@"OriginY"]] floatValue]
				   andHeight:[[themeController param:[size stringByAppendingString:@"ButtonHeight"]] floatValue]
					andWidth:[[themeController param:[size stringByAppendingString:@"ButtonWidth"]] floatValue]];		
}

-(void)buttonPressAllTables:(int)tag
{
	NSArray *tables = [windowManager getAllPokerTables];
	NSLog(@"Poker table list: %@",tables);
	
	for (id table in tables) {
		NSLog(@"If no tables, shouldn't get here.");
		AXUIElementRef tableRef = [table pointerValue];
		AXUIElementPerformAction(tableRef, kAXRaiseAction);
		
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];		
		[NSThread sleepForTimeInterval:0.3];
	}
}

-(float)getBetSize
{
	NSPoint clickPoint = [windowManager getClickPointForXSize:[[themeController param:@"betBoxOriginX"] floatValue]
										 andYSize:[[themeController param:@"betBoxOriginY"] floatValue]
										andHeight:[[themeController param:@"betBoxHeight"] floatValue]
										 andWidth:[[themeController param:@"betBoxWidth"] floatValue]];
	
	NSLog(@"x=%f,y=%f",clickPoint.x,clickPoint.y);
	AXUIElementRef betBoxRef;
	
	AXUIElementCopyElementAtPosition(appRef,
									 clickPoint.x,
									 clickPoint.y,
									 &betBoxRef);
	
	NSString *value;
	AXUIElementCopyAttributeValue(betBoxRef, kAXValueAttribute,(CFTypeRef *)&value);
	
	NSLog(@"Value:  %@",value);

	return [value floatValue];
}

-(void)setBetSize:(float)amount
{
	NSPoint clickPoint = [windowManager getClickPointForXSize:[[themeController param:@"betBoxOriginX"] floatValue]
											andYSize:[[themeController param:@"betBoxOriginY"] floatValue]
										   andHeight:[[themeController param:@"betBoxHeight"] floatValue]
											andWidth:[[themeController param:@"betBoxWidth"] floatValue]];
	
	NSLog(@"x=%f,y=%f",clickPoint.x,clickPoint.y);
	AXUIElementRef betBoxRef;
	
	AXUIElementCopyElementAtPosition(appRef,
									 clickPoint.x,
									 clickPoint.y,
									 &betBoxRef);
	
	// Set up string to the value to bet, and then strip trailing zeros if the bet is an even amount.
	NSString *valueToSet = [NSString stringWithFormat:@"%.2f",amount];
	NSLog(@"Attempting to set value: %@", valueToSet);
	if ([[valueToSet substringFromIndex:[valueToSet length]-2] isEqual:@"00"]) {
		valueToSet = [valueToSet substringToIndex:[valueToSet length]-3];
		NSLog(@"String is now: %@",valueToSet);
	}
	

	CGAssociateMouseAndMouseCursorPosition(false);
	CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown,NSPointToCGPoint(clickPoint), kCGMouseButtonLeft);
	
	// Cancel any of the modifier keys - this caused me a day of bug-hunting!
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGSessionEventTap,mouseEvent);
	
	mouseEvent = CGEventCreateMouseEvent(NULL,kCGEventLeftMouseUp,NSPointToCGPoint(clickPoint),kCGMouseButtonLeft);
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGSessionEventTap,mouseEvent);
	CGAssociateMouseAndMouseCursorPosition(true);
	
	CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL,124,true);
	CGEventSetFlags(keyEventDown,0);
	CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, 124, false);
	CGEventSetFlags(keyEventUp,0);
	
	for (int j = 0; j < 6; j++) {
		CGEventPost(kCGSessionEventTap, keyEventDown);	
		CGEventPost(kCGSessionEventTap, keyEventUp);
	}
	
	keyEventDown = CGEventCreateKeyboardEvent(NULL,51,true);
	CGEventSetFlags(keyEventDown,0);			
	keyEventUp = CGEventCreateKeyboardEvent(NULL,51,false);
	CGEventSetFlags(keyEventDown,0);			
	
	for (int j = 0; j < 10; j++) {
		CGEventPost(kCGSessionEventTap, keyEventDown);		
		CGEventPost(kCGSessionEventTap, keyEventUp);
	}
	
	UniChar buffer;
	keyEventDown = CGEventCreateKeyboardEvent(NULL, 1, true);
	keyEventUp = CGEventCreateKeyboardEvent(NULL, 1, false);
	CGEventSetFlags(keyEventDown,0);		
	CGEventSetFlags(keyEventUp,0);		
	for (int i = 0; i < [valueToSet length]; i++) {
		[valueToSet getCharacters:&buffer range:NSMakeRange(i, 1)];
		NSLog(@"Character: %c",buffer);
		CGEventKeyboardSetUnicodeString(keyEventDown, 1, &buffer);
		CGEventPost(kCGSessionEventTap, keyEventDown);
		CGEventKeyboardSetUnicodeString(keyEventUp, 1, &buffer);
		CGEventPost(kCGSessionEventTap, keyEventUp);
	}
}

-(float)betIncrement 
{
	NSArray *gameParams = [windowManager getGameParameters];
	float betIncrement; 
	
	// Get updated amountToChange;
	amountToChange = [[prefsWindowController stepper] floatValue];
	
	int row = [[prefsWindowController radiobuttonMatrix] selectedRow];
	switch(row) {
		case 0:
			betIncrement = amountToChange * [[gameParams objectAtIndex:HKBigBlind] floatValue];
			NSLog(@"amountToChange: %g  bigBlind: %g  betIncrement: %g", amountToChange,[[gameParams objectAtIndex:HKBigBlind] floatValue], betIncrement);
			break;
		case 1:
			betIncrement = amountToChange * [[gameParams objectAtIndex:HKSmallBlind] floatValue];
			NSLog(@"amountToChange: %g  smallBlind: %g  betIncrement: %g", amountToChange,[[gameParams objectAtIndex:HKSmallBlind] floatValue], betIncrement);			
			break;
	}
	return betIncrement;
}

-(void)incrementBetSize:(long)delta
{
	float betSize = [self getBetSize];
	NSLog(@"Got betsize: %g",betSize);
	betSize += [self betIncrement] * (float)delta;
	[self setBetSize:betSize];
}

-(void)decrementBetSize:(long)delta
{
	float betSize = [self getBetSize];
	NSLog(@"Got betsize: %g",betSize);
	betSize -= [self betIncrement] * (float)delta;
	[self setBetSize:betSize];
}

-(void)potBet:(int)tag
{
	NSLog(@"In potBet");
	
	float potSize = [screenScraper getPotSize];
	NSLog(@"Got pot size: %f",potSize);
	
	// Process:  need to get the value from the 
	float potBetAmt = [[potBetAmounts objectForKey:[NSNumber numberWithInt:tag]] floatValue] / 100;
	NSLog(@"Got potBetAmt: %f",potBetAmt);
	float betSize = potSize * potBetAmt;
	
	NSLog(@"New betsize: %f",betSize);
		
	if (rounding == YES) {
		NSLog(@"Rounding!");
		NSArray *gameParameters = [windowManager getGameParameters];		
		float blindSize;
		if (roundingType == 1) {
			NSLog(@"Small blind!");
			blindSize = [[gameParameters objectAtIndex:HKSmallBlind] floatValue];
		} else {
			NSLog(@"Big blind!");
			blindSize = [[gameParameters objectAtIndex:HKBigBlind] floatValue];
		}
		NSLog(@"blindSize: %f",blindSize);
		float blindAdj = blindSize * roundingAmount;
		NSLog(@"blindAdjustment: %f",blindAdj);
		if (fmod(betSize,blindAdj) != 0) {
			NSLog(@"Adjusting!");
			betSize = ((int)(betSize / blindAdj) * blindAdj) + blindAdj;			
		}

		NSLog(@"Blindsize after adjustment: %f",betSize);
	} 

	[self setBetSize:betSize];
	
	if (autoBetRounding == YES) {
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];		
	}
}

-(void)allIn
{
	[self setBetSize:99999];
	
	if (autoBetAllIn == YES) {
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];				
	}
}

-(void)leaveAllTables
{
	[self buttonPressAllTables:15];
}

-(void)sitOutAllTables
{
	[self buttonPressAllTables:10];
}


-(void)debugHK
{
	NSLog(@"In the debugging hotkey.");
	CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);

//	NSLog(@"window list: %@",windowList);
	NSMutableArray * prunedWindowList = [NSMutableArray array];
    WindowListApplierData data = {prunedWindowList, 0};
    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, &data);
    CFRelease(windowList);

	NSLog(@"pruned window list: %@",prunedWindowList);
	
	AXUIElementRef window = [windowManager getMainWindow];
	
	NSString *name;
	AXUIElementCopyAttributeValue(window,kAXTitleAttribute, (CFTypeRef *)&name);
	
	NSLog(@"Current window name: %@",name);
	NSArray *components = [name componentsSeparatedByString:@"-"];
	NSLog(@"Components: %@",components);
	
	
}

@end


pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData)
{
	NSLog(@"In hotKeyHandler!");
	
	EventHotKeyID hkCom;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
					  sizeof(hkCom),NULL,&hkCom);
	int l = hkCom.id;

	NSString *size,*prefix;
	
	// Global toggle key.
	if (l == TOGGLETAG) {
		[(id)userData toggleAllHotKeys];
		return noErr;
	}
	
	// Don't fire the keys if we're not in a poker window.
	if ([wm pokerWindowIsActive] == YES) {
		switch (l) {
			case 12:
				[(id)userData sitOutAllTables];
				break;
			case 13:
				[(id)userData incrementBetSize:1];
				break;
			case 14:
				[(id)userData decrementBetSize:1];
				break;
			case 16:
				[(id)userData leaveAllTables];
				break;
			case 17:
			case 18:
			case 19:
			case 20:
				[(id)userData potBet:l];
				break;
			case 21:
				[(id)userData allIn];
				break;
			case 99:
				[(id)userData debugHK];
				break;
			default:
				prefix = [[[(id)userData keyMap] objectForKey:[NSString stringWithFormat:@"%d",l]] objectAtIndex:0];
				size = [[[(id)userData keyMap] objectForKey:[NSString stringWithFormat:@"%d",l]] objectAtIndex:1];
				[(id)userData buttonPress:prefix withButton:size];
				break;
		}
	} else {
		return eventNotHandledErr;
	}
	return noErr;
}

pascal OSStatus mouseEventHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData)
{
//	NSLog(@"In mouse event handler!");
	if ([[[PrefsWindowController sharedPrefsWindowController] scrollWheelCheckBox] state] == NSOnState) {
		if ([wm pokerWindowIsActive] == YES) {
			long delta;
			GetEventParameter(theEvent, kEventParamMouseWheelDelta, typeSInt32, NULL, sizeof(long), NULL, &delta);
			NSLog(@"Got delta: %d",delta);
			if (delta > 0) {
				[(id)userData incrementBetSize:delta];
			} else {
				[(id)userData decrementBetSize:delta];
			}
		} else {
			CallNextEventHandler(nextHandler, theEvent);
			return eventNotHandledErr;
		}
	}
	return noErr;
}