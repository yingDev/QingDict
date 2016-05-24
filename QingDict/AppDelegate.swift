//
//  AppDelegate.swift
//  QingDict
//
//  Created by Ying on 12/3/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSDraggingDestination, NSUserNotificationCenterDelegate
{
	var statusItem: NSStatusItem! = nil;
	var axAlertController: AXAlertController? = nil;
	let txtExtractor: UserTextSelectionExtractor = UserTextSelectionExtractor();
	
	@IBOutlet var statusWindowController: StatusWindowControler!

	private var _observeCtxForWordbookEntryCount: UInt8 = 0
	
	
	deinit
	{
		statusWindowController.wordbookController.removeObserver(self, forKeyPath: "entryCount")
	}
	
	
	func applicationDidFinishLaunching(aNotification: NSNotification)
	{		
		NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
		delay(10)
		{
			self.beginCheckForUpdate(self.handleVersionCheckResult)
		}
		
		applyUserPrefs();
		
		if !AXIsProcessTrusted() { showAXAlert() }
		else
		{
			start()
			
			if nil == NSUserDefaults.standardUserDefaults().stringForKey(USER_DEFAULTS_KEY_NOTFIRSTRUN)
			{
				doFirstRunStuff()
				NSUserDefaults.standardUserDefaults().setObject("True", forKey: USER_DEFAULTS_KEY_NOTFIRSTRUN)
			}
		}
	}
	
	
	func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool
	{
		return true
	}
	
	//TODO: move strings out
	func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification)
	{
		NSWorkspace.sharedWorkspace().openURL(NSURL(string: PRODUCT_HOMEPAGE_URL)!)
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
	
	func HandleDistNoti_RemoveWordEntry(noti: NSNotification)
	{
		print("HandleDistNoti_RemoveWordEntry: \(noti.object): \(noti.userInfo)")
		
		if let dict = noti.userInfo as? [String: String]
		{
			if let word = dict["word"]
			{
				statusWindowController.wordbookController.removeEntry(word)
			}
		}
	}
	
	func HandleDistNoti_QueryStatusItemFrame(noti: NSNotification)
	{
		print("HandleDistNoti_QueryStatusItemFrame: \(noti.object): \(noti.userInfo)")

		let rect =  NSStringFromRect(statusItem.button!.window!.frame)
		NSDistributedNotificationCenter.defaultCenter().postNotificationName("QingDict:StatusItemFrame", object: "QingDict", userInfo: ["frame":rect], deliverImmediately: true)
	}

	
	@objc func lookup(pboard: NSPasteboard, userData: NSString, error: NSErrorPointer)
	{
		let str = pboard.stringForType(NSStringPboardType);
		print("yeah, we are looking up ...\(str)")
		showResult("dummy");
	}

	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
	{
		if context != &self._observeCtxForWordbookEntryCount { return }

		if let newValue = change?[NSKeyValueChangeNewKey] as? Int
		{
			var val: NSString! = nil
			
			if newValue > 99 { val = "N" }
			else if newValue > 0 { val = "\(newValue)" }

			if let oldValue = change?[NSKeyValueChangeOldKey] as? Int
			{
				//如果是添加，则稍作延迟，让用户感知到这个过程
				if newValue > oldValue
				{
					delay(0.5, closure: { 
						self.statusItem.title = "\(val)"
					})
					//statusItem.performSelector(#selector(NSStatusItem.setTitle(_:)), withObject: val, afterDelay: 0.5)
					return;
				}
			}
			
			//wtf ?
			statusItem.title = val == nil ? nil : "\(val)"
		}
	}

	
	func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation
	{
		let pboard = sender.draggingPasteboard();
		if let str = pboard.stringForType(NSStringPboardType)
		{
			print("draggingEntered: \(str)");
			statusItem.button?.highlighted = true;
		}

		return NSDragOperation.Generic;
	}
	
	func draggingExited(sender: NSDraggingInfo?)
	{
		print("draggingExited");
		statusItem.button?.highlighted = false;

	}
	
	func performDragOperation(sender: NSDraggingInfo) -> Bool
	{
		if let str = validateKeyword( sender.draggingPasteboard().stringForType(NSStringPboardType) )
		{
			showResult(str, extraArgs: ["-p", "Center", "-s", "-a"]) //auto star
			print("performDragOperation: \(str)");
		}
		
		statusItem.button?.highlighted = false
		
		return true;
	}
	
	
	private func doFirstRunStuff()
	{
		let wordbook = statusWindowController.wordbookController
		
		wordbook.addEntry(WordbookEntry(keyword: "Slide To Remove", trans: "向左/右拖拽可删除一个条目"))
		wordbook.addEntry(WordbookEntry(keyword: "Double Click", trans: "双击查看条目详情页"))
		wordbook.addEntry(WordbookEntry(keyword: "Hello World!", trans: "你好世界！我是生词表✨"))
	}
	
	private func start()
	{
		txtExtractor.onTriggered = onTriggered;
		txtExtractor.start();
		
		createStatusItem();
		
		observeDistNoti("QingDict:AddWordEntry", "HandleDistNoti_AddWordEntry:")
		observeDistNoti("QingDict:RemoveWordEntry", "HandleDistNoti_RemoveWordEntry:")
		observeDistNoti("QingDict:QueryStatusItemFrame", "HandleDistNoti_QueryStatusItemFrame:")
		
		//关联搜索框
		statusWindowController.lookupRequestHandler = lookupViaSearchBox;
		
		NSApp.servicesProvider = self;
		NSUpdateDynamicServices();
	}
	
	private func applyUserPrefs()
	{
		//TODO: refactor
		let autoStart = NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULTS_KEY_AUTOSTART)
		SMLoginItemSetEnabled(LAUNCH_HELPER_ID, autoStart)
		
	}
	
	//TODO: refactor
	private func beginCheckForUpdate(onSuccess: (ver: String, whatsNew: String)->() )
	{
		let url = NSURL(string: CHECK_FOR_UPDATE_URL)!
		let urlSession = NSURLSession.sharedSession()
		
		let task = urlSession.dataTaskWithURL(url) { (data, resp, err) -> Void in
			if err != nil
			{
				print("AppDelegate.beginCheckForUpdate: error: \(err)")
				return
			}
			
			let httpResp = resp! as! NSHTTPURLResponse
			print("AppDelegate.beginCheckForUpdate: statusCode=\(httpResp.statusCode)")
			
			if httpResp.statusCode != 200 || data == nil
			{
				return
			}
			
			do
			{
				let jsonDict = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
				
				let verEntry = jsonDict["Version"]! as! String?
				let whatsNewEntry = jsonDict["WhatsNew"]! as! String?
				
				if verEntry != nil && whatsNewEntry != nil
				{
					print("AppDelegate.beginCheckForUpdate: result: \(verEntry!), \(whatsNewEntry!)")
					
					onSuccess(ver: verEntry!, whatsNew: whatsNewEntry!)
					
				}
			}
			catch
			{
				print("AppDelegate.beginCheckForUpdate: json error: \(error)")
			}
			
		}
		
		task.resume()
	}
	
	private func handleVersionCheckResult(ver: String, whatsNew: String)
	{
		if ver == APP_VERSION { return }
		
		let noti = NSUserNotification()
		noti.title = "QingDict新版本可用！"
		noti.subtitle = "\(APP_VERSION) -> \(ver)"
		noti.informativeText = whatsNew
		
		NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(noti)
	}
	
	private func showAXAlert()
	{
		axAlertController = AXAlertController(windowNibName: "AXAlert");
		axAlertController?.onPassed = {
			self.start()
			self.axAlertController = nil
		};
		axAlertController!.showWindow(nil)
	}
	
	private func createStatusItem()
	{
		statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(40);
		statusItem.highlightMode = true;
		statusItem.image = NSImage(named: "status")
		statusItem.image?.template = true
		
		//workaround for highlight
		NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.LeftMouseDownMask)
		{
			if $0.window === self.statusItem.button?.window
			{
				self.toggleStatusWindow(self)
				return nil
			}
			return $0
		}
		
		statusItem.button!.window!.registerForDraggedTypes([NSStringPboardType]);
		statusItem.button!.window!.delegate = self;
		
		statusWindowController.onHide = { self.statusItem.button?.highlighted = false };
		
		self.statusWindowController.wordbookController.addObserver(self, forKeyPath: "entryCount", options: [.New, .Initial, .Old], context:&self._observeCtxForWordbookEntryCount)
	}
	
	private func showResult(keyword: String, extraArgs: [String] = [])
	{
		let task = NSTask();
		let appPath = NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("QingDict-Result.app/Contents/MacOS/QingDict-Result");
		
		task.launchPath = appPath!.path;
		task.arguments = ["-w", keyword] + extraArgs //, "-p", "Center"]
		
		let isStared = statusWindowController.wordbookController.containsWord(keyword)
		if isStared { task.arguments?.append("-s") }
		
		task.launch()
	}
	
	private func toggleStatusWindow(sender: NSObject)
	{
		if statusWindowController.showing
		{
			statusWindowController.hide()
			statusItem.button?.highlighted = false;
		}
		else
		{
			statusWindowController.showWindowAt(statusItem.button!.window!.frame.origin)
			statusItem.button!.highlighted = true
		}
	}
	
	private func onTriggered(kw: String?)
	{
		if let validated = validateKeyword(kw)
		{
			showResult(validated)
		}
	}
	
	private func lookupViaPasteboard()
	{
		//get content
		let pb = NSPasteboard.generalPasteboard();
		if let content = pb.stringForType(NSStringPboardType)
		{
			if let validated = validateKeyword(content)
			{
				showResult(validated)
			}
		}
		
	}
	
	private func lookupViaSearchBox(kw: String)
	{
		if let validated = validateKeyword(kw)
		{
			showResult(validated, extraArgs: ["-p", "Center"])
		}
	}
	
	private func validateKeyword(kw: String?) -> String?
	{
		if kw == nil { return nil }
		
		if !kw!.isEmpty
		{
			let len = kw!.characters.count;
			let kw = kw!.substringToIndex(kw!.startIndex.advancedBy(len > 32 ? 32 : len));
			let trimed = kw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
			
			if trimed.characters.count > 0
			{
				return trimed
			}
		}
		
		return nil;
	}

	private func observeDistNoti(name: String, _ selector: String)
	{
		NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector:Selector(selector), name: name, object: nil, suspensionBehavior: NSNotificationSuspensionBehavior.DeliverImmediately)
	}
}









