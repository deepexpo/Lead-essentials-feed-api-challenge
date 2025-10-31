//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

class LocalFeedLoader: FeedLoader {
	let store: FeedStore
	let currentDate: () -> Date

	public typealias SaveResult = Error?
	public typealias LoadResult = FeedLoader.Result

	init(_ store: FeedStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}

	func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
		store.deleteCacheFeed { [weak self] error in
			guard let self = self else { return }
			if let deletedCacheError = error {
				completion(deletedCacheError)
			} else {
				cache(items, with: completion)
			}
		}
	}

	func load(completion: @escaping (LoadResult) -> Void) {
		store.retrieve { [weak self] result in
			guard let self = self else { return }
			switch (result) {
			case let .failure(error):
				completion(.failure(error))
			case let .found(feed: localFeedImages, timeStamp: date) where FeedCachePolicy.validate(date, against: self.currentDate()):
				completion(.success(localFeedImages.toModel()))
			case .found:
				completion(.success([]))
			case .empty:
				completion(.success([]))
			}
		}
	}

	func validateCache() {
		store.retrieve { [weak self] result in
			guard let self = self else { return }
			switch (result) {
			case .failure(_):
				self.store.deleteCacheFeed { _ in }
			case let .found(feed: _, timeStamp: date) where !FeedCachePolicy.validate(date, against: self.currentDate()):
				self.store.deleteCacheFeed { _ in }
			case .found, .empty:
				break
			}
		}
	}

	private func cache(_ items: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
		store.insert(items.toLocal(), timeStamp: self.currentDate()) { [weak self] error in
			guard self != nil else { return }
			completion(error)
		}
	}
}

private extension Array where Element == FeedImage {
	func toLocal() -> [LocalFeedImage] {
		return map { LocalFeedImage(id: $0.id, desciption: $0.description, location: $0.location, url: $0.url) }
	}
}

private extension Array where Element == LocalFeedImage {
	func toModel() -> [FeedImage] {
		return map { FeedImage(id: $0.id, description: $0.desciption, location: $0.location, url: $0.url) }
	}
}
