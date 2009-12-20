//
//  HKThemeController.m
//  PokerHK
//
//  Created by Steven Hamblin on 07/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "HKThemeController.h"
#import "PrefsWindowController.h"


@implementation HKThemeController

@synthesize theme;

-(NSDictionary *)themeDictionary:(NSString *)themeName
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] 
													pathForResource:themeName ofType: @"plist"]];
	return dict;
}

-(void)awakeFromNib
{
	[[PrefsWindowController sharedPrefsWindowController] setThemeController:self];
	NSArray *themes = [NSArray arrayWithObjects:@"Hyper-Simple",@"Slick",@"Black",nil];
	NSInteger defaultIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"themeKey"];
	NSString *selectedTheme = [themes objectAtIndex:defaultIndex];
	NSLog(@"Getting the theme in themeController: %@",selectedTheme);
	[self setTheme:selectedTheme];	
}

-(void)setTheme:(NSString *)theTheme
{
	NSLog(@"Setting theme: %@",theTheme);
	theme = [theTheme copy];
	themeDict = [self themeDictionary:theme];
	NSLog(@"Theme dict is: %@", themeDict);
}

-(id)param:(NSString *)key
{
	return [themeDict objectForKey:key];
}

@end
