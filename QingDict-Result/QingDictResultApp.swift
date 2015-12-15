//
//  App.swift
//  QingDict
//
//  Created by Ying on 12/4/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Cocoa

@objc(QingDictResultApp)
class QingDictResultApp: NSApplication
{
	let cmds = ["x": "cut:", "v": "paste:", "c": "copy:", "z": "undo:", "a": "selectAll:", "Z": "redo:"];
	
	override func sendEvent(theEvent: NSEvent)
	{
		if theEvent.type == NSEventType.KeyDown
		{
			let modifier = theEvent.modifierFlags.rawValue
						   & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue;
			if (modifier == NSEventModifierFlags.CommandKeyMask.rawValue)
			{
				let cmd = cmds[theEvent.charactersIgnoringModifiers!]
				if cmd != nil && sendCmd(cmd!)
				{
					return;
				}
			}
		}
		
		super.sendEvent(theEvent);
	}
	
	private func sendCmd(cmd: String) -> Bool
	{
		return self.sendAction(Selector(cmd), to:nil, from:self);
	}
	
}

