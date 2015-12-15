//
//  WordbookEntry.swift
//  QingDict
//
//  Created by Ying on 12/14/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Foundation


class WordbookEntry
{
	var keyword: String
	var trans: String? = nil
	
	init!(keyword: String, trans: String?)
	{
		self.keyword = keyword
		self.trans = trans
	}
	
}