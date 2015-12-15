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
	@IBOutlet weak var wordbookController: WordbookViewController!
	
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
		
		wordbookController.entryDoubleClickHandler = { entry in
			self.hide()
			self.lookupRequestHandler?(entry.keyword)
		}
		
		//titleBarAccCtrl.view.wantsLayer = true;
		//titleBarAccCtrl.view.layer?.backgroundColor = CGColorCreateGenericRGB(0.8, 0.2, 0.2, 0.8);
	}
	
	func showWindowAt(pos: CGPoint)
	{
		window!.setFrame(NSRect(origin: CGPoint(x: pos.x, y: pos.y - window!.frame.height), size: window!.frame.size), display: true);
		showWindow(self);
		window!.makeKeyAndOrderFront(self);

		//window!.orderFrontRegardless()
		//window!.makeKeyWindow()
	}
	
	func hide()
	{
		window!.orderOut(self)
		onHide?()
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



