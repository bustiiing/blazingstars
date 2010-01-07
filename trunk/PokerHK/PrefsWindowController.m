//
//  PrefsWindowController.m
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//
#import "AppController.h"
#import "PrefsWindowController.h"
#import "ShortcutRecorder.h"

@class ShortcutRecorder;

@implementation PrefsWindowController
@synthesize appController;
@synthesize themeController;
@synthesize radiobuttonMatrix;
@synthesize stepper;
@synthesize scrollWheelCheckBox;
@synthesize windowFrameColourWell;


+(void)initialize {
	// If this is the first run, set up sensible default hot keys.  
	NSLog(@"Registering defaults for PrefsWindowController.");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *shortcutDefaults = [NSMutableDictionary dictionary];
	
	KeyCombo kc;

	kc.code = 3; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldKey"];
	kc.code = 8; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CallKey"];
	kc.code = 11; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetKey"];
	kc.code = 12; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckFoldKey"];	
	kc.code = 13; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldToAnyKey"];	
	kc.code = 14; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckCallKey"];	
	kc.code = 15; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckCallAnyKey"];	
	kc.code = 17; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetRaiseKey"];	
	kc.code = 16; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetRaiseAnyKey"];	
	kc.code = 35; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"SitOutKey"];		
	kc.code = 33; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"AutoPostKey"];	
	kc.code = 30; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"SitOutAllTablesKey"];	
	kc.code = 126; kc.flags = 10486016; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"IncrementKey"];	
	kc.code = 125; kc.flags = 10486016; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"DecrementKey"];	
	kc.code = 37; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"leaveTable"];	
	kc.code = 37; kc.flags = 1179914; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"leaveAllTables"];	
	kc.code = 0; kc.flags = 1179914; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"AllInKey"];		
	kc.code = 35; kc.flags = 1573160; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"ToggleAllKey"];	
	kc.code = 40; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"DebugKey"];		

	kc.code = 19; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetOneKey"];		
	kc.code = 20; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetTwoKey"];	
	kc.code = 21; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetThreeKey"];		
	kc.code = 23; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetFourKey"];	
	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:25.0] forKey:@"potBetOneKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:50.0] forKey:@"potBetTwoKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:75.0] forKey:@"potBetThreeKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:100.0] forKey:@"potBetFourKey"];	
	
    [defaults registerDefaults:shortcutDefaults];
}


-(void)awakeFromNib
{
    [self detectTheme];
    
	// Make the textfield take the initial value.
	[changeAmountField setFloatValue:[stepper floatValue]];
	
	// Set the dictionary of controls so that the dispatch controller can automatically
	// dispatch methods.
	tagDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:1],@"FoldKey",nil],[NSValue valueWithPointer:fold],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:2],@"CallKey",nil],[NSValue valueWithPointer:call],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:3],@"BetKey",nil],[NSValue valueWithPointer:bet],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:4],@"CheckFoldKey",nil],[NSValue valueWithPointer:checkFold], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:5],@"FoldToAnyKey",nil],[NSValue valueWithPointer:foldToAny], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:6],@"CheckCallKey",nil],[NSValue valueWithPointer:checkCall], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:7],@"CheckCallAnyKey",nil],[NSValue valueWithPointer:checkCallAny], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:8],@"BetRaiseKey",nil],[NSValue valueWithPointer:betRaise], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:9],@"BetRaiseAnyKey",nil],[NSValue valueWithPointer:betRaiseAny], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:10],@"SitOutKey",nil],[NSValue valueWithPointer:sitOut],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:11],@"AutoPostKey",nil],[NSValue valueWithPointer:autoPost],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:12],@"SitOutAllTablesKey",nil],[NSValue valueWithPointer:sitOutAllTables], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:13],@"IncrementKey",nil],[NSValue valueWithPointer:increment], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:14],@"DecrementKey",nil],[NSValue valueWithPointer:decrement],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:15],@"leaveTable",nil],[NSValue valueWithPointer:leaveTable],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:16],@"leaveAllTables",nil],[NSValue valueWithPointer:leaveAllTables], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:17],@"PotBetOneKey",nil],[NSValue valueWithPointer:potBetOne], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:18],@"PotBetTwoKey",nil],[NSValue valueWithPointer:potBetTwo], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:19],@"PotBetThreeKey",nil],[NSValue valueWithPointer:potBetThree], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:20],@"PotBetFourKey",nil],[NSValue valueWithPointer:potBetFour],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:21],@"AllInKey",nil],[NSValue valueWithPointer:allIn],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:22],@"ToggleAllKey",nil],[NSValue valueWithPointer:toggleAllHotkeys],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:99],@"DebugKey",nil],[NSValue valueWithPointer:debugHK],			   
			   nil];
	
	SRRecorderControl *sc; 	KeyCombo key;
	for (id tag in [tagDict allKeys]) {
		sc = [tag pointerValue];
		[sc setAnimates:YES];
		[sc setStyle:(SRRecorderStyle)SRGreyStyle];
		[sc setAllowsKeyOnly:YES escapeKeysRecord:NO];
		
		NSString *dictKey = [[tagDict objectForKey:tag] objectAtIndex:SRKEY];
		NSLog(@"Attempting to find key: %@",dictKey);
		if ([[NSUserDefaults standardUserDefaults] objectForKey:dictKey] != nil) {
			[[[NSUserDefaults standardUserDefaults] objectForKey:dictKey] getBytes:&key length:sizeof(KeyCombo)];
			[sc setKeyCombo:key];
			NSLog(@"code: %d flags: %d",key.code,key.flags);
		} else {
			KeyCombo k = [sc keyCombo];
			[[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&k length:sizeof(KeyCombo)] forKey:dictKey];
		}
	}	
	
	// Set up the pot bet fields.
	for (int i = 17; i < 21; i++) {
		[self setPotBetAmount:[potBetPrefsView viewWithTag:i]];
	}

	// Trigger the rounding controls.
	[self turnOnRounding:[potBetPrefsView viewWithTag:ROUNDINGONTAG]];
	[self setRoundingAmount:[potBetPrefsView viewWithTag:ROUNDINGAMOUNTTAG]];
	[self setRoundingType:[potBetPrefsView viewWithTag:ROUNDINGTYPETAG]];
	[self autoBetRounding:[potBetPrefsView viewWithTag:AUTOBETROUNDINGTAG]];
		
	[self autoBetAllIn:[potBetPrefsView viewWithTag:AUTOBETALLINTAG]];
	
	// Set the frame colour from the defaults.
	NSArray *colorValues = [[NSUserDefaults standardUserDefaults] objectForKey: @"windowFrameColourKey"];
	
    if(colorValues && ([colorValues count] >= 4)) {
		
		NSLog(@"Colour found!");
        NSColor *color = [NSColor colorWithDeviceRed: [[colorValues objectAtIndex: 0] floatValue]				
                                     green: [[colorValues objectAtIndex: 1] floatValue]				
                                      blue: [[colorValues objectAtIndex: 2] floatValue]				
                                     alpha: [[colorValues objectAtIndex: 3] floatValue]];
		
		
		[windowFrameColourWell setColor:color];
		
    }
	
}

-(IBAction)redetectTheme:(id)sender {
    [self detectTheme];
}

-(void)detectTheme {
    NSLog(@"Detecting theme");
    PokerStarsTheme *currentTheme = [PokerStarsInfo determineTheme];
    NSLog(@"Detected theme %@", currentTheme);
    while (![currentTheme supported]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Help"];
		[alert addButtonWithTitle:@"Redetect Theme"];
		[alert addButtonWithTitle:@"Quit"];
		[alert setMessageText:[@"BlazingStars does not support your PokerStars table theme: " stringByAppendingString:[currentTheme name]]];
		[alert setInformativeText:@"Supported themes are Black, Slick, and Hyper-Simple."];
        NSInteger result = [alert runModal];
		if (result == NSAlertThirdButtonReturn) {
            exit(0);
            
		} else if (result == NSAlertFirstButtonReturn) {
            [[NSApplication sharedApplication] showHelp:self];
            
        } else {
            currentTheme = [PokerStarsInfo determineTheme];
            NSLog(@"Detected theme %@", currentTheme);
        }
    }
    [themeController setPsTheme:currentTheme];
    [currentThemeLabel setStringValue:[currentTheme name]];
}
     
-(IBAction)setPotBetAmount:(id)sender
{
	NSLog(@"Changing pet bot amount to %f: ",[sender floatValue]);
	switch ([sender tag]) {
		case 17:
			[potStepperOneField setFloatValue:[sender floatValue]];
			[potStepperOne setFloatValue:[sender floatValue]];
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 18:
			[potStepperTwoField setFloatValue:[sender floatValue]];
			[potStepperTwo setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 19:
			[potStepperThreeField setFloatValue:[sender floatValue]];
			[potStepperThree setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 20:
			[potStepperFourField setFloatValue:[sender floatValue]];
			[potStepperFour setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		default:
			NSLog(@"setPotBetAmount:  why am I here? %d",[sender tag]);
			break;
	}
}

-(IBAction)turnOnRounding:(id)sender
{
	[appController turnOnRounding:[sender state]];
}

-(IBAction)setRoundingAmount:(id)sender
{
	[roundingStepper setFloatValue:[sender floatValue]];
	[roundingTextField setFloatValue:[roundingStepper floatValue]];
	[appController setRoundingAmount:[sender floatValue]];
}

-(IBAction)setRoundingType:(id)sender
{
	[appController setRoundingType:[sender selectedRow]];
}

-(IBAction)voiceCommandsChangedState:(id)sender
{
	[appController voiceCommandsChangedState];
}

-(IBAction)setWindowFrameColor:(id)sender
{
	NSLog(@"Setting colour to defaults!");
	NSArray *colorValues = [NSArray arrayWithObjects:							
                            [NSNumber numberWithFloat: [[windowFrameColourWell color] redComponent]],
                            [NSNumber numberWithFloat: [[windowFrameColourWell color] greenComponent]],
                            [NSNumber numberWithFloat: [[windowFrameColourWell color] blueComponent]],
                            [NSNumber numberWithFloat: [[windowFrameColourWell color] alphaComponent]],
                            nil];
	
    [[NSUserDefaults standardUserDefaults] setObject: colorValues
	 
                                              forKey: @"windowFrameColourKey"];
}

-(IBAction)autoBetRounding:(id)sender
{
	[appController autoBetRounding:[sender state]];
}

-(IBAction)autoBetAllIn:(id)sender
{
	[appController autoBetAllIn:[sender state]];
}

/* 
 * DBPrefsWindowController overrides. 
 */

-(void)setupToolbar
{
	[self addView:basicKeysPrefsView label:@"Basic Keys"];
	[self addView:potBetPrefsView label:@"Pot Bets"];
	[self addView:windowView label:@"Windows"];
	[self addView:openClosePrefsView label:@"Open:Close"];
	[self addView:setupPrefsView label:@"Setup"];
	[self addView:advancedPrefsView label:@"Advanced"];
}

// Need to override this to set the window delegate.  
- (IBAction)showWindow:(id)sender 
{
	[super showWindow:sender];
	NSLog(@"Setting the delegate!");
	[[self window] setDelegate:self];
	[[self window] makeKeyAndOrderFront:sender];
}




/*
 * Hot key functions.
 */
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSLog(@"Hot key captured in SRRC!");
	NSData *key = [NSData dataWithBytes:&newKeyCombo length:sizeof(KeyCombo)];
	[[NSUserDefaults standardUserDefaults] setObject:key
											  forKey: [[tagDict objectForKey:[NSValue valueWithPointer:aRecorder]] objectAtIndex:SRKEY]];
	[appController hkChangedFor:aRecorder withTag:[[[tagDict objectForKey:[NSValue valueWithPointer:aRecorder]] objectAtIndex:SRTAG] intValue]];
}

@end
