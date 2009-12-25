//
//  PrefsWindowController.h
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"
#import "HKThemeController.h"
#import "AppController.h"
#import "ShortcutRecorder.h"

#define SRTAG 0
#define SRKEY 1

#define ROUNDINGONTAG 900
#define ROUNDINGAMOUNTTAG 901
#define ROUNDINGTYPETAG 902
#define AUTOBETROUNDINGTAG 903
#define AUTOBETALLINTAG 904

@class AppController;
@class HKThemeController;

@interface PrefsWindowController : DBPrefsWindowController {
	// Subviews to load.
	IBOutlet NSView *basicKeysPrefsView;
	IBOutlet NSView *potBetPrefsView;
	IBOutlet NSView *openClosePrefsView;
	IBOutlet NSView *setupPrefsView;
	IBOutlet NSView *advancedPrefsView;

	// Outlets to misc. controls.
	IBOutlet NSTextField *changeAmountField;
	IBOutlet NSStepper *stepper;
	IBOutlet NSMatrix *radiobuttonMatrix;
	IBOutlet NSButton *scrollWheelCheckBox;
	IBOutlet NSStepper *potStepperOne;
	IBOutlet NSStepper *potStepperTwo;
	IBOutlet NSStepper *potStepperThree;
	IBOutlet NSStepper *potStepperFour;
	IBOutlet NSTextField *potStepperOneField;
	IBOutlet NSTextField *potStepperTwoField;
	IBOutlet NSTextField *potStepperThreeField;
	IBOutlet NSTextField *potStepperFourField;
	IBOutlet NSButton *roundPotCheckBox;
	IBOutlet NSTextField *roundingTextField;
	IBOutlet NSStepper *roundingStepper;
	IBOutlet NSMatrix *roundingMatrix;	
	
	
	AppController * appController;
	HKThemeController *themeController;
	
	// hotkey fields.
	// God, this is gross.  I wish that I could do this programmatically.
	NSArray *tagArray;
	NSDictionary *tagDict;
	IBOutlet SRRecorderControl *fold;
	IBOutlet SRRecorderControl *call;
	IBOutlet SRRecorderControl *bet;
	IBOutlet SRRecorderControl *checkFold;
	IBOutlet SRRecorderControl *foldToAny;
	IBOutlet SRRecorderControl *checkCall;
	IBOutlet SRRecorderControl *checkCallAny;
	IBOutlet SRRecorderControl *betRaise;
	IBOutlet SRRecorderControl *betRaiseAny;
	IBOutlet SRRecorderControl *sitOut;
	IBOutlet SRRecorderControl *autoPost;
	IBOutlet SRRecorderControl *sitOutAllTables;
	IBOutlet SRRecorderControl *increment;
	IBOutlet SRRecorderControl *decrement;
	IBOutlet SRRecorderControl *leaveTable;
	IBOutlet SRRecorderControl *leaveAllTables;
	IBOutlet SRRecorderControl *potBetOne;
	IBOutlet SRRecorderControl *potBetTwo;
	IBOutlet SRRecorderControl *potBetThree;
	IBOutlet SRRecorderControl *potBetFour;	
	IBOutlet SRRecorderControl *allIn;
	IBOutlet SRRecorderControl *toggleAllHotkeys;
	IBOutlet SRRecorderControl *debugHK;

	NSArray *themes;
	NSString *selectedTheme;
}
@property AppController * appController;
@property HKThemeController *themeController;
@property (copy) NSArray *themes;
@property (copy) NSString *selectedTheme;
@property IBOutlet NSMatrix *radiobuttonMatrix;
@property IBOutlet NSStepper *stepper;
@property IBOutlet NSButton *scrollWheelCheckBox;

-(IBAction)setThemeFromMenu:(id)sender;
-(IBAction)setPotBetAmount:(id)sender;
-(IBAction)turnOnRounding:(id)sender;
-(IBAction)setRoundingAmount:(id)sender;
-(IBAction)setRoundingType:(id)sender;
-(IBAction)autoBetRounding:(id)sender;
-(IBAction)autoBetAllIn:(id)sender;
@end