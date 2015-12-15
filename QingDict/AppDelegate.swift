//
//  AppDelegate.swift
//  QingDict
//
//  Created by Ying on 12/3/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSDraggingDestination
{
	var statusItem: NSStatusItem! = nil;
	var axAlertController: AXAlertController? = nil;
	let txtExtractor: UserTextSelectionExtractor = UserTextSelectionExtractor();
	
	private var observeCtxForWordbookEntryCount: UInt8 = 0
	
	@IBOutlet var statusWindowController: StatusWindowControler!
	
	deinit
	{
		self.statusWindowController.wordbookController.removeObserver(self, forKeyPath: "entryCount")
	}
	
	
	func applicationDidFinishLaunching(aNotification: NSNotification)
	{
		if !AXIsProcessTrusted()
		{
			showAXAlert();
		}
		else
		{
			start()
		}
	}
	
	func start()
	{
		txtExtractor.onTriggered = onTriggered;
		txtExtractor.start();
		
		createStatusItem();
		
		
		NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: Selector("HandleDistNoti_AddWordEntry:"), name: "QingDict:AddWordEntry", object: nil, suspensionBehavior: NSNotificationSuspensionBehavior.DeliverImmediately)
		
		//关联搜索框
		self.statusWindowController.lookupRequestHandler = lookupInternal;
		
		
		NSApp.servicesProvider = self;
		NSUpdateDynamicServices();
	}
	
	
	func showAXAlert()
	{
		axAlertController = AXAlertController(windowNibName: "AXAlert");
		axAlertController?.onPassed = {
			self.start()
			self.axAlertController = nil
		};
		axAlertController!.showWindow(nil)
	}
	
	func HandleDistNoti_AddWordEntry(noti: NSNotification)
	{
		print("HandleDistNoti_AddWordEntry: \(noti.object): \(noti.userInfo)")
		
		if let dict = noti.userInfo as? [String: String]
		{
			if let word = dict["word"]
			{
				statusWindowController.wordbookController.addEntry(WordbookEntry(keyword: word, trans: dict["trans"]))
			}
		}
	}
	
	func onTriggered(kw: String?)
	{
		if kw != nil
		{
			lookupInternal(kw!);
		}
		
	}
	
	func lookupViaPasteboard()
	{
		//get content
		let pb = NSPasteboard.generalPasteboard();
		if let content = pb.stringForType(NSStringPboardType)
		{
			lookupInternal(content);
		}
		
	}
	
	func lookupViaSearchBox(kw: String)
	{
		lookupInternal(kw)
	}
	
	func lookupInternal(kw: String)
	{
		if !kw.isEmpty
		{
			let len = kw.characters.count;
			let kw = kw.substringToIndex(kw.startIndex.advancedBy(len > 32 ? 32 : len));
			let trimed = kw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
			
			if trimed.characters.count > 0
			{
				showResult(trimed);
			}
		}
	}
	
	@objc func lookup(pboard: NSPasteboard, userData: NSString, error: NSErrorPointer)
	{
		let str = pboard.stringForType(NSStringPboardType);
		print("yeah, we are looking up ...\(str)")
		showResult("dummy");
	}
	
	func createStatusItem()
	{
		statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(45);
		statusItem.highlightMode = true;
		statusItem.image = NSImage(named: NSImageNameQuickLookTemplate)
		statusItem.image?.template = true
		
		statusItem.button!.action = Selector("toggleStatusWindow:");
		statusItem.button!.target = self;
		
		statusItem.button!.window!.registerForDraggedTypes([NSStringPboardType]);
		statusItem.button!.window!.delegate = self;
		
		statusWindowController.onHide = { self.statusItem.button?.highlighted = false };
		
		self.statusWindowController.wordbookController.addObserver(self, forKeyPath: "entryCount", options: [.New, .Initial, .Old], context:&self.observeCtxForWordbookEntryCount)
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
	{
		if context == &self.observeCtxForWordbookEntryCount
		{
			if let newValue = change?[NSKeyValueChangeNewKey] as? Int
			{
				if let oldValue = change?[NSKeyValueChangeOldKey] as? Int
				{
					//如果是添加，则稍作延迟，让用户感知到这个过程
					if newValue > oldValue
					{
						let val: NSString! = newValue == 0 ? nil: .Some("\(newValue)");
						statusItem.performSelector(Selector("setTitle:"), withObject: val, afterDelay: 0.6)
						return;
					}
				}
				
				statusItem.title = newValue == 0 ? nil : .Some("\(newValue)")
			}
		}
	}
	
	func toggleStatusWindow(sender: NSObject)
	{
		if statusWindowController.showing
		{
			statusWindowController.hide()
			statusItem.button?.highlighted = false;
		}else
		{
			statusWindowController.showWindowAt(statusItem.button!.window!.frame.origin)
			
			statusItem.button!.performSelector(Selector("setHighlighted:"), withObject: NSNumber(bool: true), afterDelay: 0.0);
		}
		
	}
	
	func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation
	{
		let pboard = sender.draggingPasteboard();
		if let str = pboard.stringForType(NSStringPboardType)
		{
			print("draggingEntered: \(str)");
		}

		return NSDragOperation.Generic;
	}
	
	func draggingExited(sender: NSDraggingInfo?)
	{
		print("draggingExited");
	}
	
	func performDragOperation(sender: NSDraggingInfo) -> Bool
	{
		let pboard = sender.draggingPasteboard();
		
		if let str = pboard.stringForType(NSStringPboardType)
		{
			lookupInternal(str)
			
		
			print("performDragOperation: \(str)");
		}
		else
		{
			return true;
		}
		
		return false;
	}
	
	func showResult(keyword: String)
	{
		let task = NSTask();
		let appPath = NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("QingDict-Result.app/Contents/MacOS/QingDict-Result");
		
		task.launchPath = appPath!.path;
		task.arguments = [keyword]
		task.launch()

	}

}









