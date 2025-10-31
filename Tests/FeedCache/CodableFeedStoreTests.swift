//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

typealias FailableFeedStore = FeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableRetriveFeedStoreSpecs & FailableDeleteFeedStoreSpecs

final class CodableFeedStoreTests: XCTestCase, FailableFeedStore {
	override func setUp() {
		super.setUp()
		removeCacheBeforeAfterTest()
	}

	override func tearDown() {
		super.tearDown()
		removeCacheBeforeAfterTest()
	}

	func test_reterive_deliverEmptyCache() {
		let sut = makeSUT()
		assertThatRetriveDeliverEmptyOnEmptyCache(on: sut)
	}

	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		expect(sut, toRetrieveTwice: .empty)
	}

	func test_retriveAfterInsertingToEmptyCache() {
		let feed = uniqueItems().local
		let sut = makeSUT()
		let timeStamp = Date()
		insert((feed, timeStamp), to: sut)
		expect(sut, toRetrieve: .found(feed: feed, timeStamp: timeStamp))
	}

	func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
		let feed = uniqueItems().local
		let sut = makeSUT()
		let timeStamp = Date()
		insert((feed, timeStamp), to: sut)
		expect(sut, toRetrieveTwice: .found(feed: feed, timeStamp: timeStamp))
	}

	func test_retrieve_deliversFailureOnRetrievalError() {
		let storeURL = testSpecificStoreURL()
		let sut = makeSUT(storeURL)
		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
		expect(sut, toRetrieve: .failure(anyNSError()))
	}

	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()

		let firstInsertionError = insert((uniqueItems().local, Date()), to: sut)
		XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

		let latestFeed = uniqueItems().local
		let latestTimestamp = Date()
		let latestInsertionError = insert((latestFeed, latestTimestamp), to: sut)

		XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
		expect(sut, toRetrieve: .found(feed: latestFeed, timeStamp: latestTimestamp))
	}

	func test_insert_deliversErrorOnInsertionError() {
		let invalidUrl = URL(string: "invalid/URL")
		let sut = makeSUT(invalidUrl)
		let feed = uniqueItems()
		let date = Date()
		let insertionError = insert((feed.local, date), to: sut)
		XCTAssertNil(insertionError, "Expected cache insertion to fail with an error")
		expect(sut, toRetrieve: .empty)
	}

	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		let deletionError = deleteCache(from: sut)
		XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
		expect(sut, toRetrieve: .empty)
	}

	func test_delete_emptiesPreviouslyInsertedCache() {
		let sut = makeSUT()
		insert((uniqueItems().local, Date()), to: sut)
		let deletionError = deleteCache(from: sut)
		XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
		expect(sut, toRetrieve: .empty)
	}

	func test_delete_deliversErrorOnDeletionError() {
		let restrictedURL = cachesDirectory()
		let sut = makeSUT(restrictedURL)
		let deletionError = deleteCache(from: sut)
		XCTAssertNotNil(deletionError, "Expected empty cache deletion to succeed")
		expect(sut, toRetrieve: .empty)
	}

	func test_storeSideEffects_runSerially() {
		let sut = makeSUT()

		var completionOrder = [XCTestExpectation]()
		let op1 = expectation(description: "First operations")
		sut.insert(uniqueItems().local, timeStamp: Date()) { _ in
			completionOrder.append(op1)
			op1.fulfill()
		}

		let op2 = expectation(description: "Second operations")
		sut.insert(uniqueItems().local, timeStamp: Date()) { _ in
			completionOrder.append(op2)
			op2.fulfill()
		}

		let op3 = expectation(description: "Third operations")
		sut.insert(uniqueItems().local, timeStamp: Date()) { _ in
			completionOrder.append(op3)
			op3.fulfill()
		}
		wait(for: [op1, op2, op3], timeout: 5.0)
		XCTAssertEqual(completionOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
	}

	// - MARK: Helpers

	private func makeSUT(_ storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
		let sut = CodableFeedStore(storeURL ?? testSpecificStoreURL())
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func removeCacheBeforeAfterTest() {
		let storeURL = testSpecificStoreURL()
		try? FileManager.default.removeItem(at: storeURL)
	}

	private func testSpecificStoreURL() -> URL {
		return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
	}

	private func cachesDirectory() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}
}
