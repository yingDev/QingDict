//
//  WordbookController.swift
//  QingDict
//
//  Created by Ying on 15/12/10.
//  Copyright © 2015年 YingDev.com. All rights reserved.
//

import Cocoa

class WordbookViewController : NSObject, NSTableViewDataSource, NSTableViewDelegate
{
	private let dataController = WordbookDataController()
	private var entries: [WordbookEntry]!
	
	var view: NSTableView! = nil
	{
		didSet
		{
			view.setDataSource(self)
			view.setDelegate(self)
			//HACK: 为什么？ 如果在当前loop直接reload，结果为空数组。
			performSelector(Selector("reload"), withObject: nil, afterDelay: 0)
			
		}
	}
	
	var entryDoubleClickHandler: ((WordbookEntry)->())? = nil
	
	//kvo compatible
	dynamic private(set) var entryCount: Int = 0
	
	func containsWord(word: String) -> Bool
	{
		return entries == nil ? false : entries.contains({ e -> Bool in
			return word == e.keyword
		})
	}
	
	func addEntry(entry: WordbookEntry)
	{
		dataController.add(entry)
		reload()
	}
	
	func removeEntry(word: String)
	{
		dataController.remove(word)
		reload()
	}
	
	func reload()
	{
		entries = dataController.fetchAll()
		entryCount = entries.count
		
		view.reloadData()
	}
	
	func numberOfRowsInTableView(tableView: NSTableView) -> Int
	{
		return entryCount
	}
	
	func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
	{
		let rowView = tableView.makeViewWithIdentifier("mainCell", owner: nil) as! WordbookRowView
		
		let model = entries![row] //WordbookEntry(keyword: "English \(row)", trans: "n.英语 \(row)")
		
		rowView.txtTittle.stringValue = model.keyword;
		rowView.txtTrans.stringValue = model.trans == nil ? "" : model.trans! //.stringByReplacingOccurrencesOfString("  ", withString: " ").stringByReplacingOccurrencesOfString("\n", withString: " ")
		
		rowView.onSwiped = {sender in
			let r = tableView.rowForView(sender)
			let indexes = NSIndexSet(index: r);
			tableView.removeRowsAtIndexes(indexes, withAnimation: [.EffectFade, .SlideUp])
			
			//not removeEntry here. for effeciency
			self.dataController.remove(self.entries[r].keyword)
			self.entries.removeAtIndex(r)
			self.entryCount = self.entries.count
		}
		
		rowView.onClicked = { sender, clickCount in
			if clickCount == 1
			{
				let indexes = NSIndexSet(index: tableView.rowForView(sender));
				tableView.selectRowIndexes(indexes, byExtendingSelection: false);
			}else if clickCount == 2 //双击
			{
				let r = tableView.rowForView(sender)
				
				self.entryDoubleClickHandler?(self.entries[r]);
				
				print("double Click")
			}
			
		}
				
		return rowView;

	}

	
	func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int)
	{
		print("tableView setObjectValue")
	}
	
}
