//
//  main.m
//  Launch-Helper
//
//  Created by Ying on 12/17/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject<NSApplicationDelegate>

- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
	pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 4)];
	
	NSString *path = [NSString pathWithComponents:pathComponents];

	
	[[NSWorkspace sharedWorkspace] launchApplication:path];
	
	[NSApp terminate:nil];
}

@end


int main(int argc, const char * argv[])
{
	NSApp = [NSApplication sharedApplication];
	
	id del = [[AppDelegate alloc] init];
	
	NSApp.delegate = del;
	
	[NSApp run];
}
