//
//  PrefsViewController.swift
//  QingDict
//
//  Created by Ying on 12/16/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa
import ServiceManagement

class PrefsViewController : NSViewController
{
	
	@IBOutlet weak var contentView: NSView!
	@IBOutlet weak var autoStartBtn: NSButton!
	@IBOutlet weak var versionTxt: NSTextField!
	@IBOutlet weak var youdaoTxt: NSTextField!
	
	override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	required init?(coder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func awakeFromNib()
	{
		super.awakeFromNib()
		
	}
	
	override func viewDidLayout()
	{
		super.viewDidLayout()

		self.contentView.setFrameOrigin(NSPoint(x: 0, y: self.view.frame.size.height ))

	}

	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.contentView.setFrameOrigin(NSPoint(x: 0, y: self.view.frame.size.height ))

		(self.contentView as! SolidColorView).color = NSColor.windowBackgroundColor()
		
		autoStartBtn.state = NSUserDefaults.standardUserDefaults().boolForKey(USER_DEFAULTS_KEY_AUTOSTART) ? NSOnState : NSOffState
		
		versionTxt.stringValue = APP_VERSION
		
	}

	func animIn()
	{
		self.contentView.animator().setFrameOrigin(NSPoint(x: 0, y: 0))

	}
	
	func animOut()
	{
		self.contentView.animator().setFrameOrigin(NSPoint(x: 0, y: self.view.frame.size.height ))

	}
	
	@IBAction func quit(sender: AnyObject)
	{
		NSApp.performSelector(#selector(NSApplication.terminate(_:)), withObject: nil, afterDelay: 0.08)
	}
	
	@IBAction func switchAutostart(sender: AnyObject)
	{
		let btn = sender as! NSButton
		
		let enabled = btn.state == NSOnState ? true : false
		
		SMLoginItemSetEnabled(LAUNCH_HELPER_ID, enabled)
		
		//TODO: refactor
		NSUserDefaults.standardUserDefaults().setBool(enabled, forKey: USER_DEFAULTS_KEY_AUTOSTART)
		NSUserDefaults.standardUserDefaults().synchronize()
		
	}
	
	
	@IBAction func followLink(sender: NSButton)
	{
		if sender.tag == 0
		{
			NSWorkspace.sharedWorkspace().openURL(NSURL(string: PRODUCT_HOMEPAGE_URL)!)
		}else
		{
			NSWorkspace.sharedWorkspace().openURL(NSURL(string: PRODUCT_DONATE_URL)!)
		}
		
		sender.enabled = false;
		delay(0.5)
		{
			sender.enabled = true
		}
	}
	
	/*private func youdaoUrlHack()
	{
		let attMutStr = NSMutableAttributedString(string: youdaoTxt.stringValue)
		attMutStr.beginEditing()
		let youdaoLink = NSAttributedString(string: "youdao.com",
			attributes: [NSLinkAttributeName : "http://youdao.com",
				NSForegroundColorAttributeName: NSColor.blueColor(),
				NSUnderlineStyleAttributeName: NSNumber(int: Int32(NSUnderlineStyle.StyleSingle.rawValue))])
		
		attMutStr.appendAttributedString(youdaoLink)
		
		//add alignment
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .Center
		attMutStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0,attMutStr.length))
		
		attMutStr.endEditing()
		
		youdaoTxt.attributedStringValue = attMutStr
		
	}*/
	
	
}
