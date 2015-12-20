//
//  AppDelegate.swift
//  QingDict-Result
//
//  Created by Ying on 12/7/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa
import WebKit
import CommandLine


@NSApplicationMain
class ResultAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate
{
	@IBOutlet weak var window: ResultWindow!
	
	var timeWindowShown: CFAbsoluteTime = 0

	func applicationDidFinishLaunching(aNotification: NSNotification)
	{
		let cli = CommandLine()
		let word = StringOption(shortFlag: "w", longFlag: "word", required: true, helpMessage: "the word to translate")
		let pos = StringOption(shortFlag: "p", longFlag: "pos", required: false, helpMessage: "window pos: Center / Cursor")
		let isStared = BoolOption(shortFlag: "s", longFlag: "stared", required: false, helpMessage: "is this word in wordbook?")
		
		let autoStar = BoolOption(shortFlag: "a", longFlag: "autostar", required: false, helpMessage: "auto star this word")
		
		cli.addOptions(word, pos, isStared, autoStar)
		
		do {
			try cli.parse()
		}catch
		{
			cli.printUsage(error)
			NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
			return;
		}
		
		let keyword = word.value!; //Process.arguments[1];
		
		if let encoded = keyword.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
		{
			let url = "http://dict.youdao.com/search?q=\(encoded)";
			
			
			self.window.stared = isStared.value
			self.window.shouldAutoStar = autoStar.value

			self.window!.loadUrl(url);
			self.window!.title = keyword;
			
			performSelector(Selector("showWindowWithPos:"), withObject: pos.value==nil ? "Cursor" : pos.value! , afterDelay: 0.2)
			//showWindowWithPos(pos.value == nil ? .Cursor : pos.value!)

		}else
		{
			NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
		}
	}
	
	func showWindowWithPos(pos: String)
	{
		print("ResultAppDelegate.showWindowWithPos: \(pos)")
		
		let winSize = self.window!.frame.size;
		var winPos = CGPoint()

		switch pos
		{
		
		case "Center":
			let screenFrame = NSScreen.mainScreen()!.frame;
			let screenCenter = NSPoint(x: screenFrame.width/2 + screenFrame.origin.x, y: screenFrame.height/2 + screenFrame.origin.y)
			winPos = CGPoint(x: screenCenter.x - winSize.width/2, y: screenCenter.y - winSize.height/4)
			break;
			
		default:
		//case "Cursor":
			let cursorPos = NSEvent.mouseLocation();
			winPos = CGPoint(x: cursorPos.x + 8, y: cursorPos.y - 8 - winSize.height)
			break;
		}
		
		self.window!.setFrameOrigin(winPos)
		self.window!.makeKeyAndOrderFront(nil);
		
		timeWindowShown = CFAbsoluteTimeGetCurrent()
	}
	
	func windowDidResignKey(notification: NSNotification)
	{
		if CFAbsoluteTimeGetCurrent() - timeWindowShown > 0.5
		{
			print("ResultAppDelegate.windowDidResignKey: terminate")

			NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
			return;
		}

		print("ResultAppDelegate.windowDidResignKey: not time")
		self.window!.makeKeyAndOrderFront(nil);
	}

}

