//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

protocol FeedStoreSpecs {
	func test_reterive_deliverEmptyCache()
	func test_retrieve_hasNoSideEffectsOnEmptyCache()

	func test_retriveAfterInsertingToEmptyCache()
	func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues()
	func test_insert_overridesPreviouslyInsertedCacheValues()
	func test_delete_hasNoSideEffectsOnEmptyCache()

	func test_delete_emptiesPreviouslyInsertedCache()

	func test_storeSideEffects_runSerially()
}

protocol FailableRetriveFeedStoreSpecs: FeedStoreSpecs {
	func test_retrieve_deliversFailureOnRetrievalError()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
	func test_insert_deliversErrorOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
	func test_delete_deliversErrorOnDeletionError()
}
