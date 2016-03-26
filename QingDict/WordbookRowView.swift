//
//  WordbookView.swift
//  QingDict
//
//  Created by Ying on 15/12/10.
//  Copyright © 2015年 YingDev.com. All rights reserved.
//

import Cocoa

class WordbookRowView : NSTableRowView
{
	var swipeDist = CGFloat(80)

	@IBOutlet weak var txtTittle: NSTextField!
	@IBOutlet weak var txtTrans: NSTextField!
	
	@IBOutlet weak var contentView: SolidColorView!
	
	var warnBackgroundColor = NSColor(red: 255/255.0, green: 63/255.0, blue: 68/255.0, alpha: 1);
	var normBackgroundColor = NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1);
	var selectionColor = NSColor(red: 0.6, green: 0.8, blue: 1, alpha: 0.2)
	
	//quick-dirty ... for now
	var onSwiped: ((NSTableRowView)->())? = nil
	var onClicked: ((NSTableRowView, Int)->())? = nil
	
	private var _startDragPoint: CGPoint = CGPoint()
	private var _lastDragPoint: CGPoint = CGPoint()
	private var _selectedStateBeforeDrag: Bool = false;
	private var _willRemoveAfterDragRelease: Bool = false
	private var _lastClickTime: CFAbsoluteTime = 0;
	
	
	/*override func drawBackgroundInRect(dirtyRect: NSRect)
	{
		//let ctx = NSGraphicsContext.currentContext();
		//ctx?.saveGraphicsState()
		
		//if _willRemoveAfterDragRelease
		//{
		//	warnBackgroundColor.setFill()
		//}else
		//{
			backgroundColor.setFill()
		//}
		
		//NSColor.clearColor().setFill()
		NSRectFill(dirtyRect)
	}*/

	
	override func drawSelectionInRect(dirtyRect: NSRect)
	{
		//什么也不画。屏蔽默认行为
	}
	
	override func mouseDragged(theEvent: NSEvent)
	{
		let dx = _lastDragPoint.x - theEvent.locationInWindow.x
		
		let isOverDist = abs(_startDragPoint.x - theEvent.locationInWindow.x) > swipeDist
		if isOverDist != _willRemoveAfterDragRelease
		{
			_willRemoveAfterDragRelease = isOverDist;
			if _willRemoveAfterDragRelease
			{
				self.animator().backgroundColor = self.warnBackgroundColor
			}else
			{
				self.animator().backgroundColor = normBackgroundColor
			}
		}
		
		contentView.setFrameOrigin(NSPoint(x: contentView.frame.origin.x - dx, y: contentView.frame.origin.y))
		
		_lastDragPoint = theEvent.locationInWindow
	}
	
	override func mouseDown(theEvent: NSEvent)
	{
		//hack: 略奇怪：background的默认值似乎总是会被某个调用者设成某个颜色
		self.backgroundColor = normBackgroundColor

		_willRemoveAfterDragRelease = false;
		_startDragPoint = theEvent.locationInWindow
		_lastDragPoint = _startDragPoint
		_selectedStateBeforeDrag = selected;
	}
	
	override func mouseUp(theEvent: NSEvent)
	{
		let CLICK_DIST = CGFloat(2)

		let dx = abs(_lastDragPoint.x - _startDragPoint.x)
		if dx >= swipeDist
		{
			Swift.print("mouse swipe!")

			onSwiped?(self)
			
		}else if dx <= CLICK_DIST
		{
			//click
			onClicked?(self, theEvent.clickCount)
			Swift.print("mouse click!")

		}else
		{
			Swift.print("mouse nothing!")
			
			
			contentView.animator().setFrameOrigin(NSPoint(x: 0, y: contentView.frame.origin.y))
			
		}
		
		_willRemoveAfterDragRelease = false;
		setNeedsDisplayInRect(self.bounds)
		
		contentView.setFrameOrigin(NSPoint(x: 0, y: contentView.frame.origin.y))
	}
	
	override var selected: Bool
	{
		didSet
		{
			contentView.color = selected ? selectionColor : NSColor.whiteColor()
		}
	}
	
	override func setFrameSize(newSize: NSSize)
	{
		super.setFrameSize(newSize)
		
		swipeDist = self.frame.width / 2;
	}
	
	deinit
	{
		Swift.print("WordbookRowView.deinit")
	}
	
}

class SwipableTableView : NSTableView
{
	override func validateProposedFirstResponder(responder: NSResponder, forEvent event: NSEvent?) -> Bool {
		return true;
	}
}

class SolidColorView : NSView
{
	var color = NSColor.whiteColor()
	
	override func drawRect(dirtyRect: NSRect)
	{
		color.setFill()
		NSRectFill(dirtyRect)
	}
}