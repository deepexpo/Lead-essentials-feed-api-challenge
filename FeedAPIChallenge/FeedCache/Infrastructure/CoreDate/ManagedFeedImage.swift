//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: ManagedCache

	static func images(from localfeed: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
		return NSOrderedSet(array: localfeed.map({ local in
			let managed = ManagedFeedImage(context: context)
			managed.id = local.id
			managed.imageDescription = local.desciption
			managed.location = local.location
			managed.url = local.url
			return managed
		}))
	}

	var local: LocalFeedImage {
		return LocalFeedImage(id: id, desciption: imageDescription, location: location, url: url)
	}
}
