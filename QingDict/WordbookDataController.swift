//
//  WordEntry.swift
//  QingDict
//
//  Created by Ying on 12/14/15.
//  Copyright © 2015 YingDev.com. All rights reserved.
//

import Foundation
import CoreData

class WordbookDataController: NSObject
{
	private let ENTITY_NAME = "WordbookEntry"
	private var ctx: NSManagedObjectContext!
	
	override init()
	{
		super.init()
		
		// This resource is the same name as your xcdatamodeld contained in your project.
		guard let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension:"momd") else {
			fatalError("Error loading model from bundle")
		}
		// The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
		guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
			fatalError("Error initializing mom from: \(modelURL)")
		}
		let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
		self.ctx = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		self.ctx.persistentStoreCoordinator = psc
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
			let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
			let docURL = urls[urls.endIndex-1].URLByAppendingPathComponent(NSBundle.mainBundle().bundleIdentifier!)
			
			if !NSFileManager.defaultManager().fileExistsAtPath(docURL.path!)
			{
				do
				{
					try NSFileManager.defaultManager().createDirectoryAtPath(docURL.path!, withIntermediateDirectories: true, attributes: nil)

				}catch
				{
					fatalError("Error create app support dir: \(error)")
				}
			}
			
			
			let storeURL = docURL.URLByAppendingPathComponent("Model.sqlite")
			do {
				try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
			} catch
			{
				fatalError("Error migrating store: \(error)")
			}
		}
	}
	
	private func _get(word: String) -> WordbookEntryMO?
	{
		let fetch = NSFetchRequest(entityName: ENTITY_NAME)
		fetch.predicate = NSPredicate(format: "word == %@", word)
		
		do
		{
			let res = try ctx.executeFetchRequest(fetch) as! [WordbookEntryMO]
			
			if res.count > 0
			{
				return res[0]
			}else
			{
				return nil
			}
			
		} catch
		{
			fatalError("Failed to fetch: \(error)")
		}

	}
	
	func get(word: String) -> WordbookEntry?
	{
		return _get(word)?.toPlain()
	}
	
	func add(entry: WordbookEntry) -> Bool
	{
		if _get(entry.keyword) != nil
		{
			return false
		}
		
		let mo = NSEntityDescription.insertNewObjectForEntityForName(ENTITY_NAME, inManagedObjectContext: self.ctx) as! WordbookEntryMO;
		
		mo.word = entry.keyword;
		mo.trans = entry.trans;
		
		do
		{
			try self.ctx.save()
			return true
		} catch
		{
			fatalError("Failure to save context: \(error)")
		}
	}
	
	func remove(key: String)
	{
		if let entry = _get(key)
		{
			ctx.deleteObject(entry)
			do {
				try ctx.save()
			}catch
			{
				fatalError("WordbookDataController.remove failed: \(error)")
			}
		}
	}
	
	func fetchAll() -> [WordbookEntry]
	{
		let fetch = NSFetchRequest(entityName: ENTITY_NAME)

		do{

			let res = try ctx.executeFetchRequest(fetch) as! [WordbookEntryMO]
			
			return res.reverse().map({ mo -> WordbookEntry in
				return mo.toPlain()
			})
		}catch
		{
			fatalError("Failure to executeFetchRequest: \(error)")
		}
		
		
		return []
	}
}

class WordbookEntryMO : NSManagedObject
{
	@NSManaged var word: String!
	@NSManaged var trans: String?
	
	func toPlain() -> WordbookEntry
	{
		return WordbookEntry(keyword: word, trans: trans)
	}
}