//
//  Consts.swift
//  QingDict
//
//  Created by Ying on 12/17/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Foundation

let LAUNCH_HELPER_ID = "com.yingdev.Launch-Helper"

let USER_DEFAULTS_KEY_AUTOSTART = "AutoStart"
let USER_DEFAULTS_KEY_NOTFIRSTRUN = "NotFirstRun"

let PRODUCT_HOMEPAGE_URL = "http://www.yingdev.com/projects/QingDict"
let PRODUCT_DONATE_URL = "http://www.yingdev.com/home/donate"
let CHECK_FOR_UPDATE_URL = "http://www.yingdev.com/projects/latestVersion?product=QingDict"

var APP_VERSION: String { return NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String }