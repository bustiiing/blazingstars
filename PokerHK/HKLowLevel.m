//
//  HKLowLevel.m
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-07.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import "HKLowLevel.h"


@implementation HKLowLevel

@synthesize appName,pokerstarsPID,appRef;

-(id)init 
{
	if ((self = [super init])) {
		logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
		[logger info:@"Initializing low-level interface in HKLowLevel."];
	
		if (!AXAPIEnabled()) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Accessibility API must be activated in the Universal Access Preferences Pane."];
			[alert setInformativeText:@"Make sure that the \"Enable access for assistive devices\" check box is selected at the bottom of the preference pane.  BlazingStars will now quit to allow you to modify the settings."];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];
		}
				
		NSWorkspace * ws = [NSWorkspace sharedWorkspace];
		NSArray * apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationName"];

		if ([apps containsObject:@"PokerStarsIT"]) {
			appName = [NSString stringWithFormat:@"PokerStarsIT"];
		} else if ([apps containsObject:@"PokerStars"]) {
			appName = [NSString stringWithFormat:@"PokerStars"];
		} else {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"PokerStars client not found!"];
			[alert setInformativeText:@"The PokerStars client must be running for this program to operate.  Please start the client and then re-open BlazingStars."];
			[NSApp activateIgnoringOtherApps:YES];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];			
		}

		NSArray *pids = [[NSWorkspace sharedWorkspace] launchedApplications];
		
		for (id app in pids) {
			if ([[app objectForKey:@"NSApplicationName"] isEqualToString: appName]) {
				pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
			}		
		}		
		
		appRef = AXUIElementCreateApplication(pokerstarsPID);
		
		if (!appRef) {
			[logger critical:@"Could not get accessibility API reference to the PokerStars application."];
			NSException* apiException = [NSException
										 exceptionWithName:@"PokerStarsNotFoundException"
										 reason:@"Cannot get accessibility API reference to the PokerStars application."									
										 userInfo:nil];
			@throw apiException;
		}		
		
		
		NSNotificationCenter *center = [ws notificationCenter];
		[center addObserver:self
				   selector:@selector(appTerminated:)
					   name:NSWorkspaceDidTerminateApplicationNotification
					 object:nil];
		
	}
	return self;
}

-(BOOL)pokerStarsClientIsActive
{
	NSWorkspace * ws = [NSWorkspace sharedWorkspace];
	NSArray * apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationName"];

	return [apps containsObject:appName];
}

-(AXUIElementRef)getFrontMostApp
{
	pid_t pid;
	ProcessSerialNumber psn;
	
	GetFrontProcess(&psn);
	GetProcessPID(&psn, &pid);
	return AXUIElementCreateApplication(pid);	
}

-(NSArray *)getChildrenFrom:(AXUIElementRef)ref
{
	NSArray *children;
	AXError err = AXUIElementCopyAttributeValues(appRef, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);

	if (err != kAXErrorSuccess) {
		[logger warning:@"Retrieving children failed. Error code: %d", err];
		return nil;
	}
	return children;
}


-(void)appTerminated:(NSNotification *)note
{
	if ([[[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"] isEqual:[NSNumber numberWithInt:pokerstarsPID]]) {
		[logger notice:@"PokerStars terminated - quitting BlazingStars."];
		[[NSApplication sharedApplication] terminate: nil];
	}
}


@end
