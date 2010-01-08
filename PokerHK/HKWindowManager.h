//
//  HKWindowManager.h
//  PokerHK
//
//  Created by Steven Hamblin on 09/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SOLogger/SOLogger.h>
#import "HKDefines.h"
#import "HKDispatchController.h"
#import "HKThemeController.h"
#import "HKLowLevel.h"

enum {
	HKNotTable = 0,
	HKTournamentTable = 1,
	HKTournamentLobby = 2,
	HKTournamentPopup = 3,
	HKHoldemCashTable = 4,
	HKGeneralTable = 5,
	HKTournamentRegistration = 6,
	HKTablePopup = 7,
	HKPLOTable = 8,
};



#define HKSizePos 0

@class HKDispatchController;
@class HKThemeController;

@interface HKWindowManager : NSObject {
	AXObserverRef observer;

	IBOutlet HKDispatchController *dispatchController;
	IBOutlet HKThemeController *themeController;
	IBOutlet HKLowLevel *lowLevel;
	
	NSMutableDictionary *windowDict;
	BOOL activated;
	NSWindow *frameWindow;
	
	SOLogger *logger;
}

@property BOOL activated;

-(void)debugWindow:(NSRect)windowRect;
-(void)drawWindowFrame;
-(void)clickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width;
-(NSPoint)getClickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width;
-(void)updateWindowDict;
-(BOOL)pokerWindowIsActive;
-(int)windowIsTable:(AXUIElementRef)windowRef;
-(int)windowIsTableAtOpening:(AXUIElementRef)windowRef;
-(AXUIElementRef)getMainWindow;
-(NSArray *)getAllPokerTables;
-(NSRect)getWindowBounds:(AXUIElementRef)windowRef;
-(NSRect)getPotBounds:(AXUIElementRef)windowRef;
-(NSArray *)getGameParameters;
-(double)findTournamentNum:(NSString *)title inLobby:(BOOL)lobbyBool;
-(void)windowDidOpen:(AXUIElementRef)elementRef;
-(void)windowDidResize:(AXUIElementRef)elementRef;
-(void)windowDidClose:(AXUIElementRef)elementRef;
-(void)windowFocusDidChange;
-(void)windowDidMove;
-(void)applicationDidActivate;
-(void)applicationDidDeactivate;
@end
