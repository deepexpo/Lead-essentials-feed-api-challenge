//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
import Foundation
@testable import FeedAPIChallenge

class FeedStoreSpy: FeedStore {
	enum ReceivedMessage: Equatable {
		case deletedCacheFeed
		case insert([LocalFeedImage], Date)
		case retrieve
	}

	private var deletionCompletions = [DeletionCompletion]()
	private var insertCompletion = [InsertCompletion]()
	private var retrivalCompletion = [RetrivalCompletion]()

	private(set) var receivedMessages = [ReceivedMessage]()

	func deleteCacheFeed(completion: @escaping DeletionCompletion) {
		deletionCompletions.append(completion)
		receivedMessages.append(.deletedCacheFeed)
	}

	func completeWithDeletion(with error: Error, at index: Int = 0) {
		deletionCompletions[index](.failure(error))
	}

	func completeDeletionSuccessfully(at index: Int = 0) {
		deletionCompletions[index](.success(()))
	}

	func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertCompletion) {
		insertCompletion.append(completion)
		receivedMessages.append(.insert(items, timeStamp))
	}

	func completeWithInsertion(with error: Error, at index: Int = 0) {
		insertCompletion[index](.failure(error))
	}

	func completeInsertionSuccessfully(at index: Int = 0) {
		insertCompletion[index](.success(()))
	}

	func retrieve(completion: @escaping RetrivalCompletion) {
		retrivalCompletion.append(completion)
		receivedMessages.append(.retrieve)
	}

	func completeRetrive(with error: Error, at index: Int = 0) {
		retrivalCompletion[index](.failure(error))
	}

	func completeRetriveSuccessfully(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
		retrivalCompletion[index](.success((feed: feed, timeStamp: timestamp)))
	}

	func completeRetrievalWithEmptyCache(at index: Int = 0) {
		retrivalCompletion[index](.success(CacheFeed(feed: [], timeStamp: Date())))
	}
}
