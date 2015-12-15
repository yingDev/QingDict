//
//  WordbookController.swift
//  QingDict
//
//  Created by Ying on 15/12/10.
//  Copyright © 2015年 YingDev.com. All rights reserved.
//

import Cocoa

class WordbookViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate
{
	private let dataController = WordbookDataController()
	private var entries: [WordbookEntry]!
	
	@IBOutlet weak var tableView: NSTableView!
	
	var entryDoubleClickHandler: ((WordbookEntry)->())? = nil
	
	//kvo compatible
	dynamic private(set) var entryCount: Int = 0
	
	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.backgroundColor = NSColor.clearColor()

		reload()
	}
	
	func addEntry(entry: WordbookEntry)
	{
		dataController.add(entry)
		reload()
	}
	
	private func reload()
	{
		entries = dataController.fetchAll()
		entryCount = entries.count
		
		tableView.reloadData()
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
