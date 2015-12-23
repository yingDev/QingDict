//
// Created by Ying on 11/23/15.
// Copyright (c) 2015 YingDev.com. All rights reserved.
//

import Foundation
import CoreGraphics

private func callback(proxy: CGEventTapProxy, type: CGEventType,event: CGEvent, ptr: UnsafeMutablePointer<Void>) -> Unmanaged<CGEvent>?
{
	//TODO: handle this
	//失效
	/*if type == CGEventType.TapDisabledByTimeout || type == CGEventType.TapDisabledByUserInput
	{
		print("MouseMonitor: disabled by \(type)")
		
		
		return Unmanaged<CGEvent>.passUnretained(event)
	}*/
	
    let selv = Unmanaged<MouseMonitor>.fromOpaque(COpaquePointer(ptr)).takeUnretainedValue()
    if(selv.handler != nil)
    {
        let pos = CGEventGetLocation(event)
		if let e = selv.handler!(event, type, pos)
		{
			return Unmanaged<CGEvent>.passUnretained(e)
		}else
		{
			return nil
		}
		
    }


    return Unmanaged<CGEvent>.passUnretained(event)
}


public class MouseMonitor
{
	typealias TapEventHandler = ((CGEvent, CGEventType, CGPoint) -> CGEvent?);
	
    var _tap: CFMachPort?
    var _runloop_source: CFRunLoopSource?
	var handler: TapEventHandler?;
	

    init(handler: TapEventHandler? = nil)
    {
        _tap = CGEventTapCreate(CGEventTapLocation.CGHIDEventTap,
                CGEventTapPlacement.HeadInsertEventTap,
                CGEventTapOptions.Default,
                CGEventMask((1 << CGEventType.RightMouseDown.rawValue) /*| (1 << CGEventType.RightMouseUp.rawValue)*/),
                callback, UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque()))

        self.handler = handler
    }

    func install()
    {
        if (_tap != nil)
        {
            _runloop_source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), _runloop_source, kCFRunLoopCommonModes)
        }else
        {
            //todo: throw?
            print("Fail CGEventTapCreate")
        }
    }

    func set_enabled(enabled: Bool)
    {
        CGEventTapEnable(_tap!, enabled)
    }

    func is_enabled() -> Bool
    {
        return CGEventTapIsEnabled(_tap!)
    }


    deinit
    {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runloop_source, kCFRunLoopCommonModes)
    }
}

