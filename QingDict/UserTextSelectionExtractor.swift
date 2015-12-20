//
//  UserTextSelectionExtractor.swift
//  QingDict
//
//  Created by Ying on 12/14/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa

class UserTextSelectionExtractor : NSObject, NSWindowDelegate, NSDraggingDestination
{
	var onTriggered: ((String?)->())?;
	
	//防止触发太频繁
	private let _performMinInterval: CFTimeInterval = 1.5
	private var _lastPerformTime: CFAbsoluteTime = 0;

	private var _mouseMonitor: MouseMonitor? = nil;
	private var _dragDropWin: NSPanel? = nil; //TODO: 用来显示图标
	private var _dragDropKeyword: String? = nil;
	private var _sysWideAxElem: AXUIElement!
	private var _axKeyword: String? = nil;
	
	private var _extracted = false //三种取词手段同时执行，抢占锁
	
	
	func start()
	{
		_mouseMonitor = MouseMonitor();
		_mouseMonitor?.handler = handleMouseEvent
		_mouseMonitor?.install();
		
		_dragDropWin = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 24,height: 24), styleMask: NSHUDWindowMask | NSNonactivatingPanelMask, backing: NSBackingStoreType.Buffered, `defer`: false);
		_dragDropWin?.hidesOnDeactivate = false;
		_dragDropWin?.delegate = self;
		_dragDropWin?.oneShot = false;
		_dragDropWin?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.3)
		_dragDropWin?.registerForDraggedTypes([NSStringPboardType]);
		_dragDropWin?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.DraggingWindowLevelKey))
		_dragDropWin?.hasShadow = false;
		let imgView = NSImageView();
		imgView.image = NSImage(named: "status_white")
		imgView.highlighted = true;
		_dragDropWin?.contentView = imgView
		
		_sysWideAxElem = AXUIElementCreateSystemWide().takeRetainedValue()
	}
	
	private func handleMouseEvent(e: CGEvent, type: CGEventType, p: CGPoint) -> CGEvent?
	{
		let leftPressed = NSEvent.pressedMouseButtons() & 1 == 1
		if !leftPressed || type != CGEventType.RightMouseDown
		{
			return e;
		}
		
		//is too frequent?
		let now = CFAbsoluteTimeGetCurrent()
		if now - _lastPerformTime < _performMinInterval
		{
			return nil;
		}
		
		print("UserTextSelectionExtractor.handleMouseEvent:")
		_lastPerformTime = now;
		_extracted = false;
		_dragDropKeyword = nil;
		_axKeyword = nil;
		
		print("\t RightButtonDown")
		
		// show dragDrop window
		let curPos = NSEvent.mouseLocation();
		_dragDropWin!.alphaValue = 1
		_dragDropWin?.setFrameOrigin(NSPoint(x: curPos.x + 1, y: curPos.y - 11))
		_dragDropWin?.orderFrontRegardless()
		
		delay(0.01)
		{
			self.tryGetByAX()
			self.tryGetByCmdC()
			self.tryGetByDragDrop(NSValue(point: p))
		}
		
		return nil
	}
	
	private func tryGetByAX()
	{
		print("UserTextSelectionExtractor.tryGetByAX:")
		var focElem: AnyObject? = nil
		var err = AXError.Success
		
		err = AXUIElementCopyAttributeValue(_sysWideAxElem, kAXFocusedUIElementAttribute, &focElem);
		if err != .Success
		{
			print("\t kAXFocusedUIElementAttribute Error: \(err)")
			return;
		}
		
		var selTxt: AnyObject? = nil
		err = AXUIElementCopyAttributeValue(focElem! as! AXUIElement, kAXSelectedTextAttribute, &selTxt)
		if err != .Success
		{
			print("\t kAXSelectedTextAttribute Error: \(err)")
			return;
		}
		
		_axKeyword = selTxt! as? String
		print("\t got: \(_axKeyword)")
		
		_delayedPerformOnTriggered()
		
	}
	
	private func tryGetByCmdC()
	{
		if _extracted { return }
		
		let key_c_down = CGEventCreateKeyboardEvent(nil, 8, true)
		let key_c_up = CGEventCreateKeyboardEvent(nil, 8, false)
		CGEventSetFlags(key_c_down, CGEventFlags.MaskCommand);
		CGEventSetFlags(key_c_up, CGEventFlags.MaskCommand);
		
		CGEventPost(CGEventTapLocation.CGSessionEventTap, key_c_down)
		CGEventPost(CGEventTapLocation.CGSessionEventTap, key_c_up)
	}
	
	private func tryGetByDragDrop(pos: NSValue)
	{
		delay(0.4)
		{
			self._dragDropWin!.animator().alphaValue = 0
		}

		if _extracted { return }
		
		let moveTo = CGPoint(x: pos.pointValue.x + 6, y: pos.pointValue.y)
		let drag = CGEventCreateMouseEvent(nil, CGEventType.LeftMouseDragged, moveTo, CGMouseButton.Left);
		let move = CGEventCreateMouseEvent(nil, CGEventType.MouseMoved, moveTo, CGMouseButton.Left);
		CGEventPost(CGEventTapLocation.CGSessionEventTap, drag);
		CGEventPost(CGEventTapLocation.CGSessionEventTap, move);
		
		delay(0.1)
		{
			let moveBack = CGEventCreateMouseEvent(nil, CGEventType.LeftMouseDragged, pos.pointValue, CGMouseButton.Left);
			CGEventPost(CGEventTapLocation.CGSessionEventTap, moveBack)
			
			if self._extracted { return }
			
			// Left up: 使cmd＋c生效
			let left_up = CGEventCreateMouseEvent(nil, CGEventType.LeftMouseUp, pos.pointValue, CGMouseButton.Left);
			CGEventPost(CGEventTapLocation.CGSessionEventTap, left_up)
			
			//try for cmd + c
			delay(0.15)
			{
				self._delayedPerformOnTriggered()
			}
		}
	}
	
	func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation
	{
		print("UserTextSelectionExtractor.draggingEntered");

		if _extracted { return NSDragOperation.None; }
		
		if let str = sender.draggingPasteboard().stringForType(NSStringPboardType)
		{
			_dragDropKeyword = str;
			delay(0.01)
			{
				self._delayedPerformOnTriggered()
			}
		}
		return NSDragOperation.Generic;
	}
	
	func _delayedPerformOnTriggered()
	{
		if _extracted { return }
		_extracted = true;
		
		print("UserTextSelectionExtractor._delayedPerformOnTriggered:")
		var kw: String?;
		if _axKeyword != nil
		{
			print("\t axKeyword=\(_axKeyword)");
			kw = _axKeyword
		}else if _dragDropKeyword != nil
		{
			print("\t dragDroppedKeyword=\(_dragDropKeyword)");
			kw = _dragDropKeyword;
			_dragDropKeyword = nil
		}else
		{
			let pb = NSPasteboard.generalPasteboard();
			kw = pb.stringForType(NSStringPboardType)
			print("\t pasteBoard=\(kw)");
		}
		
		onTriggered?(kw)
	}

}


