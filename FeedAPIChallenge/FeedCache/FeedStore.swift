//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

public typealias CacheFeed = (feed: [LocalFeedImage], timeStamp: Date)
protocol FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertCompletion = (Error?) -> Void
	typealias RetrivealResult = Swift.Result<CacheFeed?, Error>
	typealias RetrivalCompletion = (RetrivealResult) -> Void
	func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertCompletion)
	func deleteCacheFeed(completion: @escaping DeletionCompletion)
	func retrieve(completion: @escaping RetrivalCompletion)
}
