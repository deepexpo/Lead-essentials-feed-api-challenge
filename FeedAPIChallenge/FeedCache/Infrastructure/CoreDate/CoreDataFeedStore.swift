//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public final class CoreDataFeedStore: FeedStore {
	public init(storeURL: URL, bundle: Bundle = .main) throws {
		container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
		context = container.newBackgroundContext()
	}

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertCompletion) {
		perform { context in
			do {
				let managedCache = ManagedCache(context: context)
				managedCache.timeStamp = timeStamp
				managedCache.feed = ManagedFeedImage.images(from: items, in: context)
				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	func deleteCacheFeed(completion: @escaping DeletionCompletion) {
		perform { context in
			do {
				try ManagedCache.find(in: context).map(context.delete).map(context.save)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	func retrieve(completion: @escaping RetrivalCompletion) {
		perform { context in
			do {
				if let cache = try ManagedCache.find(in: context) {
					completion(.success(.found(feed: cache.localFeed, timeStamp: cache.timeStamp)))
				} else {
					completion(.success(.empty))
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
		let context = self.context
		context.perform {
			action(context)
		}
	}
}
