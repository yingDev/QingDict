//
//  UserTextSelectionExtractor.swift
//  QingDict
//
//  Created by Ying on 12/14/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Foundation
import Cocoa

class UserTextSelectionExtractor : NSObject, NSWindowDelegate, NSDraggingDestination
{
	var onTriggered: ((String?)->())?;
	
	private var hiddenDragDropWindow: NSPanel? = nil; //TODO: 用来显示图标
	private var dragDroppedKeyword: String? = nil;
	private var mouseMonitor: MouseMonitor? = nil;
	
	func start()
	{
		mouseMonitor = MouseMonitor();
		mouseMonitor?.handler = handleMouseEvent
		mouseMonitor?.install();
		
		hiddenDragDropWindow = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 10,height: 10), styleMask: NSHUDWindowMask | NSNonactivatingPanelMask, backing: NSBackingStoreType.Buffered, `defer`: false);
		hiddenDragDropWindow?.hidesOnDeactivate = false;
		hiddenDragDropWindow?.delegate = self;
		hiddenDragDropWindow?.oneShot = false;
		hiddenDragDropWindow?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.2)
		hiddenDragDropWindow?.registerForDraggedTypes([NSStringPboardType]);
		hiddenDragDropWindow?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.UtilityWindowLevelKey))
		hiddenDragDropWindow?.hasShadow = false;
	}
	
	private func handleMouseEvent(e: CGEvent, type: CGEventType, p: CGPoint) -> CGEvent?
	{
		let leftPressed = NSEvent.pressedMouseButtons() & 1 == 1;
		
		if !leftPressed
		{
			return e;
		}
		
		let src: CGEventSource? = nil;//CGEventSourceCreate(CGEventSourceStateID.HIDSystemState);
		let loc = CGEventTapLocation.CGSessionEventTap
		
		if type == CGEventType.RightMouseDown
		{
			dragDroppedKeyword = nil;
			print("RDown")
			
			//Cmd + C
			let key_c_down = CGEventCreateKeyboardEvent(src, 8, true)
			let key_c_up = CGEventCreateKeyboardEvent(src, 8, false)
			CGEventSetFlags(key_c_down, CGEventFlags.MaskCommand);
			CGEventSetFlags(key_c_up, CGEventFlags.MaskCommand);
			
			CGEventPost(loc, key_c_down)
			CGEventPost(loc, key_c_up)
			
			// dragDrop
			
			let curPos = NSEvent.mouseLocation();
			hiddenDragDropWindow?.setFrame(NSRect(x: curPos.x, y: curPos.y - 5, width: 10,height: 10), display: true);
			hiddenDragDropWindow?.makeKeyAndOrderFront(nil)
			
			//停留足够的时间，才能让系统认为是拖拽
			NSThread.sleepForTimeInterval(0.1)
			
			let drag = CGEventCreateMouseEvent(src, CGEventType.LeftMouseDragged, CGPoint(x: p.x + 6, y: p.y), CGMouseButton.Left);
			
			let move = CGEventCreateMouseEvent(src, CGEventType.MouseMoved, CGPoint(x: p.x + 6, y: p.y), CGMouseButton.Left);
			
			let moveBack = CGEventCreateMouseEvent(src, CGEventType.LeftMouseDragged, CGPoint(x: p.x, y: p.y), CGMouseButton.Left);
			
			CGEventPost(loc, drag);
			CGEventPost(loc, move);
			CGEventPost(loc, moveBack)
			
			return nil;
			
		}
		else if type == CGEventType.RightMouseUp
		{
			print("RUp")
			
			// Left up
			let left_up = CGEventCreateMouseEvent(src, CGEventType.LeftMouseUp, CGPoint(x: p.x, y: p.y), CGMouseButton.Left);
			
			CGEventPost(loc, left_up)
			
			self.performSelector(Selector("_delayedPerformOnTriggered"), withObject: nil, afterDelay: 0.2)
			
			hiddenDragDropWindow!.performSelector(Selector("orderOut:"), withObject: nil, afterDelay: 0.1);
			return nil;
		}
		
		return e;
	}
	
	
	func _delayedPerformOnTriggered()
	{
		var kw: String?;
		if dragDroppedKeyword == nil
		{
			print("lookupViaPasteboard");
			let pb = NSPasteboard.generalPasteboard();
			kw = pb.stringForType(NSStringPboardType)
		}else
		{
			print("dragDroppedKeyword: \(dragDroppedKeyword!)");
			kw = dragDroppedKeyword;
		}

		onTriggered?(kw)
	}

}


