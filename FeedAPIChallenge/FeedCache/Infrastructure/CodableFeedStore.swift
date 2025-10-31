//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

public final class CodableFeedStore: FeedStore {
	private struct Cache: Codable {
		let feeds: [CodableFeedImage]
		let timeStamp: Date

		var localFeed: [LocalFeedImage] {
			return feeds.map { $0.local }
		}
	}

	private struct CodableFeedImage: Codable {
		private let id: UUID
		private let description: String?
		private let location: String?
		private let url: URL

		init(_ image: LocalFeedImage) {
			id = image.id
			description = image.desciption
			location = image.location
			url = image.url
		}

		var local: LocalFeedImage {
			return LocalFeedImage(id: id, desciption: description, location: location, url: url)
		}
	}

	private let storeURL: URL

	private let queue = DispatchQueue(label: "\(CodableFeedStore.self) Queue", qos: .userInitiated, attributes: .concurrent)

	init(_ storeUrl: URL) {
		self.storeURL = storeUrl
	}

	func retrieve(completion: @escaping RetrivalCompletion) {
		let url = storeURL
		queue.async {
			guard let data = try? Data(contentsOf: url) else { return completion(.success(.empty)) }
			let decoder = JSONDecoder()
			do {
				let cache = try decoder.decode(Cache.self, from: data)
				completion(.success(.found(feed: cache.localFeed, timeStamp: cache.timeStamp)))
			} catch {
				completion(.failure(error))
			}
		}
	}

	func insert(_ feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertCompletion) {
		let url = storeURL
		queue.async(flags: .barrier) {
			let encoder = JSONEncoder()
			do {
				let encodedData = try encoder.encode(Cache(feeds: feed.map { CodableFeedImage($0) }, timeStamp: timeStamp))
				try encodedData.write(to: url)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	func deleteCacheFeed(completion: @escaping DeletionCompletion) {
		let url = storeURL
		queue.async(flags: .barrier) {
			guard FileManager.default.fileExists(atPath: url.path) else { return completion(nil) }
			do {
				try FileManager.default.removeItem(at: url)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
}
