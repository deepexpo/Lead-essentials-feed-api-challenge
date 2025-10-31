//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedCache)
 class ManagedCache: NSManagedObject {
	@NSManaged var timeStamp: Date
	@NSManaged var feed: NSOrderedSet

	var localFeed: [LocalFeedImage] {
		return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
	}

	static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
		request.returnsObjectsAsFaults = false
		return try context.fetch(request).first
	}
}
