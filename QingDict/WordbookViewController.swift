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

			reload()
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
	
	func clearSelection()
	{
		if view.selectedRow >= 0
		{
			let lastSelectedRow = view.rowViewAtRow(view.selectedRow, makeIfNecessary: false)! as! WordbookRowView;
			lastSelectedRow.txtTrans.hidden = true;
			lastSelectedRow.contentView.constraints.filter({ cons in cons.identifier == "centerY" })[0].priority = 751;
			lastSelectedRow.txtTittle.textColor = NSColor.darkGrayColor();
			
			view.selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
		}
	}
	
	func numberOfRowsInTableView(tableView: NSTableView) -> Int
	{
		return entryCount
	}
	
	func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
	{
		let rowView = tableView.makeViewWithIdentifier("mainCell", owner: nil) as! WordbookRowView
		
		let model = entries![row]
		
		rowView.txtTittle.stringValue = model.keyword;
		rowView.txtTrans.stringValue = model.trans == nil ? "" : model.trans!
		rowView.txtTrans.hidden = true;
		
		rowView.onSwiped = self.handleRowSwiped
		rowView.onClicked = self.handleRowClicked
				
		return rowView;

	}
	
	private func handleRowClicked(sender: WordbookRowView, clickCount: Int)
	{
		if clickCount == 1
		{
			clearSelection()
			
			let indexes = NSIndexSet(index: view.rowForView(sender));
			view.selectRowIndexes(indexes, byExtendingSelection: false);
			
			sender.txtTrans.hidden = false;
			sender.txtTittle.textColor = NSColor.blackColor()
			
			sender.contentView.constraints.filter({ cons in cons.identifier == "centerY" })[0].priority = 749;
			
			
		}else if clickCount == 2 //双击
		{
			let r = view.rowForView(sender)
			
			self.entryDoubleClickHandler?(self.entries[r]);
			
			print("double Click")
		}

	}
	
	private func handleRowSwiped(sender: WordbookRowView)
	{
		let r = view.rowForView(sender)
		let indexes = NSIndexSet(index: r);
		view.removeRowsAtIndexes(indexes, withAnimation: [.EffectFade, .SlideUp])
		
		self.dataController.remove(self.entries[r].keyword)
		self.entries.removeAtIndex(r)
		self.entryCount = self.entries.count
	}

	func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool
	{
		return false;
	}
}
