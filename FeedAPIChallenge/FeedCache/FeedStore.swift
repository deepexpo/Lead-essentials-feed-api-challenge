//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

public enum RetrieveCacheFeedResult {
	case empty
	case found(feed: [LocalFeedImage], timeStamp: Date)
	case failure(Error)
}

protocol FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertCompletion = (Error?) -> Void
	typealias RetrivalCompletion = (RetrieveCacheFeedResult) -> Void
	func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertCompletion)
	func deleteCacheFeed(completion: @escaping DeletionCompletion)
	func retrieve(completion: @escaping RetrivalCompletion)
}
