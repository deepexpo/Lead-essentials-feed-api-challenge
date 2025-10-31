//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs, FailableInsertFeedStoreSpecs, FailableDeleteFeedStoreSpecs {
	func test_retrieve_deliversEmptyOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetriveDeliverEmptyOnEmptyCache(on: sut)
	}

	func test_reterive_deliverEmptyCache() {}

	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_retriveAfterInsertingToEmptyCache() {
		let sut = makeSUT()
		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}

	func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
		let sut = makeSUT()
		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}

	func test_insert_deliversErrorOnInsertionError() {
		let sut = makeSUT()
		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}

	func test_delete_deliversErrorOnDeletionError() {}

	func test_insert_overridesPreviouslyInsertedCacheValues() {}

	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}

	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()
		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}

	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()
		assertThatSideEffectsRunSerially(on: sut)
	}

	//Helper

	func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedStore {
		let storeBundle = Bundle(for: CoreDataFeedStore.self)
		let storeURL = URL(fileURLWithPath: "/dev/null")
		let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
}
