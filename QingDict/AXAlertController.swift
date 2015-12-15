//
//  AXAlertController.swift
//  QingDict
//
//  Created by Ying on 15/12/7.
//  Copyright © 2015年 YingDev.com. All rights reserved.
//

import Cocoa


class AXAlertController : NSWindowController
{
	var onPassed: (()->())? = nil;
	
	func pollingCheck()
	{
		if AXIsProcessTrusted()
		{
			onPassed?();
			onPassed = nil;
			self.close();
			return;
		}
		
		performSelector(Selector("pollingCheck"), withObject: nil, afterDelay: 0.3)
	}
	
	override func windowDidLoad()
	{
		self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.UtilityWindowLevelKey))
		pollingCheck();
	}
	
	@IBAction func quit(sender: AnyObject)
	{
		NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0)
	}
	
	@IBAction func allow(sender: AnyObject)
	{
		if AXIsProcessTrusted()
		{
			onPassed?();
			onPassed = nil;
			self.close();
			return;
		}
		
		//wtf interop ?!! -_-!
		let val = true;
		var keys = [UnsafePointer<Void>(kAXTrustedCheckOptionPrompt.toOpaque())];
		var values = [unsafeAddressOf(val)];
		var keyCallBacks = kCFTypeDictionaryKeyCallBacks
		var valueCallBacks = kCFTypeDictionaryValueCallBacks
		
		let options = CFDictionaryCreate(kCFAllocatorDefault,
			&keys, &values, 1, &keyCallBacks, &valueCallBacks);
		
		AXIsProcessTrustedWithOptions(options)
	}
	
}
