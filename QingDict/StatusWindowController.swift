//
//  StatusWindowController.swift
//  QingDict
//
//  Created by Ying on 15/12/11.
//  Copyright © 2015年 YingDev.com. All rights reserved.
//

import Cocoa

class StatusWindowControler : NSWindowController, NSWindowDelegate
{
	@IBOutlet weak var searchField: NSSearchField!
	@IBOutlet weak var toolbarView: SolidColorView!
	
	@IBOutlet weak var wordbookViewWrapper: NSView!
	@IBOutlet weak var wordbookTableView: SwipableTableView!
	
	var wordbookController: WordbookViewController!
	var prefsController: PrefsViewController? = nil
	
	var lookupRequestHandler: ((String)->())? = nil
	
	//quick & dirty
	var onHide: (()->())? = nil;
	
	var showing: Bool
	{
		return window == nil ? false : window!.visible
	}
	
	override func awakeFromNib()
	{
		window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.DockWindowLevelKey))
		
		window!.opaque = false;
		window?.backgroundColor = NSColor.clearColor()
		
		window!.movable = false
		
		wordbookTableView.backgroundColor = NSColor.clearColor()
		wordbookController = WordbookViewController()
		wordbookController.view = wordbookTableView;
		wordbookController.entryDoubleClickHandler = {
			self.hide()
			self.lookupRequestHandler?($0.keyword)
		}
		
		toolbarView.color = NSColor.windowBackgroundColor()
	}
	
	func showWindowAt(pos: CGPoint)
	{
		//防止跑出屏外
		var safeX = pos.x;
		if let screenWidth = NSScreen.mainScreen()?.frame.width
		{
			if pos.x + window!.frame.width > screenWidth
			{
				safeX = screenWidth - window!.frame.width
			}
		}
		
		window!.setFrame(NSRect(origin: CGPoint(x: safeX, y: pos.y - window!.frame.height), size: window!.frame.size), display: true);
		showWindow(self);
		window!.makeKeyAndOrderFront(self);
		
		searchField.becomeFirstResponder()

		//window!.orderFrontRegardless()
		//window!.makeKeyWindow()
	}
	
	func hide()
	{
		window!.orderOut(self)
		onHide?()
		wordbookController.clearSelection()
	}
	
	//FIXME: searchField 无法每次都活的焦点
	func windowDidBecomeKey(notification: NSNotification)
	{
	}
	
	func windowDidResignKey(notification: NSNotification)
	{
		hide()
	}
	
	@IBAction func searchField_search(sender: NSSearchField)
	{
		hide()
		lookupRequestHandler?(sender.stringValue)
	}
	
	@IBAction func togglePrefsView(sender: AnyObject)
	{
		let btn = (sender as! NSButton);
		btn.enabled = false;
		
		if prefsController == nil
		{
			prefsController = PrefsViewController(nibName: "PrefsView", bundle: NSBundle.mainBundle())
			prefsController!.view.frame = wordbookViewWrapper.frame
			self.window?.contentView?.addSubview(prefsController!.view)
			
			wordbookViewWrapper.hidden = true

			delay(0.1)
			{
				self.prefsController?.animIn()
			}
			
			delay(0.2)
			{
				self.toolbarView.color = NSColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1);

				(self.window?.contentView as! ButtomRoundedView).fillColor = NSColor.windowBackgroundColor()
				self.window?.contentView?.setNeedsDisplayInRect(self.window!.contentView!.bounds)
				btn.enabled = true;
			}
		}else
		{
			self.prefsController?.animOut()
			(self.window?.contentView as! ButtomRoundedView).fillColor = NSColor.whiteColor()
			self.window?.contentView?.setNeedsDisplayInRect(self.window!.contentView!.bounds)

			delay(0.2)
			{
				self.prefsController?.view.removeFromSuperview()
				self.prefsController = nil
				
				self.wordbookViewWrapper.hidden = false
				self.toolbarView.color = NSColor.windowBackgroundColor()
				self.window?.contentView?.setNeedsDisplayInRect(self.window!.contentView!.bounds)

				btn.enabled = true;
			}
			
		}
	}
	
	
}

class StatusWindow : NSPanel
{
	override var canBecomeKeyWindow: Bool
	{
		return true;
	}
	
	override var canBecomeMainWindow: Bool { return true }
}

class ButtomRoundedView : NSView
{
	var fillColor: NSColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
	var cornerRadius: CGFloat = 14;
	
	override func drawRect(dirtyRect: NSRect)
	{
		
		var controlPoint = CGPoint();
		let path = NSBezierPath()
		let b = self.bounds;
		
		let left = NSMinX(b);
		let right = NSMaxX(b);
		let top = NSMaxY(b);
		let bottom = NSMinY(b);
		
		// Start drawing from upper left corner
		path.moveToPoint(NSPoint(x: left, y: top))
		
		// Draw right border, bottom border and left border
		path.lineToPoint(NSPoint(x: right, y: top))
		path.lineToPoint(NSPoint(x: right, y: bottom + cornerRadius))
		

		//right-bottom curve
		controlPoint = NSPoint(x: right, y: bottom);
		path.curveToPoint(NSPoint(x: right - cornerRadius, y: bottom), controlPoint1: controlPoint, controlPoint2: controlPoint)
		
		path.lineToPoint(NSPoint(x: left + cornerRadius, y: bottom))
		
		//left-bottom curve
		controlPoint = NSPoint(x: left, y: bottom)
		path.curveToPoint(NSPoint(x: left, y: bottom + cornerRadius), controlPoint1: controlPoint, controlPoint2: controlPoint)
		
		path.lineToPoint(NSPoint(x: left, y: top))
		// Fill path
		fillColor.setFill()
		path.fill()
	}
}



