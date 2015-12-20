//
//  Util.swift
//  QingDict
//
//  Created by Ying on 12/17/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Foundation

func delay(delay:Double, closure:()->())
{
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}
