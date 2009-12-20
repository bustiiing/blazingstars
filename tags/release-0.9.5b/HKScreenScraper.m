//
//  HKScreenScraper.m
//  PokerHK
//
//  Created by Steven Hamblin on 16/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "HKScreenScraper.h"
#import "NSImage+MGCropExtensions.h"
#import "TFTesseractWrapper.h"
#import "OpenGLScreenReader.h"

static NSRect FlippedScreenBounds(NSRect bounds)
{
    float screenHeight = NSMaxY([[[NSScreen screens] objectAtIndex:0] frame]);
    bounds.origin.y = screenHeight - NSMaxY(bounds);
	NSLog(@"BOUNDS: %f",bounds.origin.y);
    return bounds;
}


@implementation HKScreenScraper

-(void)awakeFromNib
{
	NSWorkspace * ws = [NSWorkspace sharedWorkspace];
	NSArray *pids = [ws launchedApplications];
	
	for (id app in pids) {
		if ([[app objectForKey:@"NSApplicationName"] isEqualToString: @"PokerStars"]) {
			pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		}
	}
	
	appRef = AXUIElementCreateApplication(pokerstarsPID);
	
}

-(NSString *)runTesseract:(NSString *)inFilePath
{
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString * absolutePath = [thisBundle pathForResource:@"tesseract" ofType:@""];
	//NSLog(@"executable path: %@", absolutePath);
	
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: absolutePath];
	
	NSString * tessdataPath = [NSString stringWithFormat:@"%@/", [thisBundle resourcePath]];
	NSMutableDictionary * environ = [NSMutableDictionary dictionaryWithDictionary:[task environment]];
	[environ setObject:tessdataPath forKey:@"TESSDATA_PREFIX"];
	
	//NSLog(@"env: %@", environ);
	[task setEnvironment:environ];
	
	char tempfilename[1024];
	strcpy(tempfilename, "/tmp/tmp_tesseract_gui_XXXXXX");
	char * tfile = mktemp(tempfilename);
	NSString *outputFileName = [NSString stringWithCString:tfile encoding:NSUTF8StringEncoding];
	
	NSString * inputPath = inFilePath;
	//NSLog(@"input path: %@, output file name %@", inputPath, outputFileName);
	
	NSArray *arguments = [NSArray arrayWithObjects:inputPath, outputFileName, nil];
	
	[task setArguments: arguments];
	[task launch];
	[task waitUntilExit];
	
	NSString * ofile = [NSString stringWithFormat:@"%@.txt",outputFileName];
	NSString * output = [NSString stringWithContentsOfFile:ofile encoding:NSUTF8StringEncoding error:nil];
	if(output == nil)
		output = [NSString stringWithString:@"Error reading tesseract output"];
	
	int retval = unlink([ofile cStringUsingEncoding:NSUTF8StringEncoding]);
	if(retval)
		NSLog(@"Failed to unlink: %@", ofile);
	
	return output;
}


-(float)getPotSize
{
	NSLog(@"In getPotSize");
	AXUIElementRef mainWindow = [windowManager getMainWindow];
	NSRect windowRect = [windowManager getPotBounds:mainWindow];

	NSLog(@"windowRect sx=%f sy=%f h=%f w=%f",windowRect.origin.x,
		  windowRect.origin.y,windowRect.size.height,windowRect.size.width);

#ifdef HKDEBUG
	[windowManager debugWindow:windowRect];
#endif

	NSRect cropRect = FlippedScreenBounds(windowRect);
	NSLog(@"cropRect sx=%f sy=%f h=%f w=%f",cropRect.origin.x,cropRect.origin.y,cropRect.size.height,cropRect.size.width);
	CGImageRef screenCap;
    OpenGLScreenReader *mOpenGLScreenReader = [[OpenGLScreenReader alloc] init];
	
	[mOpenGLScreenReader readFullScreenToBuffer];
	screenCap = [mOpenGLScreenReader createImage];
	
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:screenCap];
	// Create an NSImage and add the bitmap rep to it...
	NSImage *imageConvert = [[NSImage alloc] init];
	[imageConvert addRepresentation:bitmapRep];
	[bitmapRep release];
	
	NSImage *cropped = [imageConvert imageFromRect:cropRect];
	NSData *tiffData = [cropped TIFFRepresentation];
	[tiffData writeToFile:@"/tmp/testimage.tif" atomically:NO];
	
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString * absolutePath = [thisBundle pathForResource:@"convert" ofType:@""];
	NSLog(@"executable path: %@", absolutePath);
	
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: absolutePath];
	
	NSString *inputPath = [NSString stringWithString:@"/tmp/testimage.tif"];
	NSString *outputfilename = [NSString stringWithString:@"/tmp/processed.tif"];
//	NSArray *arguments = [NSArray arrayWithObjects:inputPath,@"-despeckle", @"-resample",@"600x600",outputfilename, nil];
	NSArray *arguments = [NSArray arrayWithObjects:inputPath,@"-resample",@"600x600",
						@"-colorspace",@"Gray",@"-unsharp",@"7.4x3.0+3.0+0.0",outputfilename, nil];	
	
	[task setArguments: arguments];
	NSLog(@"Arguments: %@",[task arguments]);
	
	[task launch];	
	[task waitUntilExit];
	
	NSString *result = [self runTesseract:@"/tmp/processed.tif"];
	
	// Need to do some string processing on this thing.
	NSLog(@"Pot size is: %@",result);
	float returnVal;
	
	result = [result stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSLog(@"Pot after stripping spaces: %@",result);

 	NSCharacterSet *excludeSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789,."] invertedSet];
	
	result = [result stringByTrimmingCharactersInSet:excludeSet];
	NSLog(@"Pot after stripping exclude set: %@",result);
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];	
	[formatter setGeneratesDecimalNumbers:YES];
	NSNumber *pot = [formatter numberFromString:result];
	NSLog(@"New pot value from formatter is: %g",[pot doubleValue]);
	returnVal = [pot floatValue];
	
	
	// Use the fact that any decimal followed by more than two digits is a comma.  
	NSRange position = [result rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
	if (position.location != NSNotFound) {
		NSLog(@"Position of decimal: %d",position.location);
	}

	return returnVal;
}

@end