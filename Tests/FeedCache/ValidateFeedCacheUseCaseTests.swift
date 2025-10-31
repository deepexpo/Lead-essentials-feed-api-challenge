//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

final class ValidateFeedCacheUseCaseTests: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func test_init_doesNotMessgaeOnStoreCreation() {
		let (_, store) = makeSut()
		XCTAssertEqual(store.receivedMessages.count, 0)
	}

	func test_validateCache_deletesCacheOnRetrievalError() {
		let (sut, store) = makeSut()
		sut.validateCache()
		store.completeRetrive(with: anyNSError())

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deletedCacheFeed])
	}

	func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
		let (sut, store) = makeSut()

		sut.validateCache()
		store.completeRetrievalWithEmptyCache()

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_validateCache_doesNotDeleteLessThanSevenDaysOldCache() {
		let feed = uniqueItems()
		let fixedCurrenDate = Date()
		let lessthenSevenDayTimestamp = fixedCurrenDate.adding(days: -7).adding(seconds: 1)
		let (sut, store) = makeSut(currentDate: { fixedCurrenDate })
		sut.validateCache()
		store.completeRetriveSuccessfully(with: feed.local, timestamp: lessthenSevenDayTimestamp)
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_validateCache_deletesSevenDaysOldCache() {
		let feed = uniqueItems()
		let fixedCurrentDate = Date()
		let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		sut.validateCache()
		store.completeRetriveSuccessfully(with: feed.local, timestamp: sevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deletedCacheFeed])
	}

	func test_validateCache_deletesMoreThanSevenDaysOldCache() {
		let feed = uniqueItems()
		let fixedCurrentDate = Date()
		let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		sut.validateCache()
		store.completeRetriveSuccessfully(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)

		XCTAssertEqual(store.receivedMessages, [.retrieve, .deletedCacheFeed])
	}

	func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
		let store = FeedStoreSpy()
		var sut: LocalFeedLoader? = LocalFeedLoader(store, currentDate: Date.init)
		sut?.validateCache()

		sut = nil
		store.completeRetrive(with: anyNSError())
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	//Helpers
	private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
		let store = FeedStoreSpy()
		let sut = LocalFeedLoader(store, currentDate: currentDate)
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, store)
	}
}
