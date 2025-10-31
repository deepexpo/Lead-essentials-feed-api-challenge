//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

extension FeedStoreSpecs where Self: XCTestCase {
	func assertThatRetriveDeliverEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		expect(sut, toRetrieve: .empty, file: file, line: line)
	}

	func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		expect(sut, toRetrieveTwice: .empty, file: file, line: line)
	}

	func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		let feed = uniqueItems().local
		let timestamp = Date()

		insert((feed, timestamp), to: sut)

		expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
	}

	func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		let feed = uniqueItems().local
		let timestamp = Date()

		insert((feed, timestamp), to: sut)

		expect(sut, toRetrieveTwice: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
	}

	func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		let insertionError = insert((uniqueItems().local, Date()), to: sut)

		XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
	}

	func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		insert((uniqueItems().local, Date()), to: sut)

		let insertionError = insert((uniqueItems().local, Date()), to: sut)

		XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
	}

	func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		insert((uniqueItems().local, Date()), to: sut)

		let latestFeed = uniqueItems().local
		let latestTimestamp = Date()
		insert((latestFeed, latestTimestamp), to: sut)

		expect(sut, toRetrieve: .found(feed: latestFeed, timeStamp: latestTimestamp), file: file, line: line)
	}

	func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		let deletionError = deleteCache(from: sut)

		XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
	}

	func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		deleteCache(from: sut)

		expect(sut, toRetrieve: .empty, file: file, line: line)
	}

	func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		insert((uniqueItems().local, Date()), to: sut)

		let deletionError = deleteCache(from: sut)

		XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
	}

	func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		insert((uniqueItems().local, Date()), to: sut)

		deleteCache(from: sut)

		expect(sut, toRetrieve: .empty, file: file, line: line)
	}

	func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
		var completedOperationsInOrder = [XCTestExpectation]()

		let op1 = expectation(description: "Operation 1")
		sut.insert(uniqueItems().local, timeStamp: Date()) { _ in
			completedOperationsInOrder.append(op1)
			op1.fulfill()
		}

		let op2 = expectation(description: "Operation 2")
		sut.deleteCacheFeed { _ in
			completedOperationsInOrder.append(op2)
			op2.fulfill()
		}

		let op3 = expectation(description: "Operation 3")
		sut.insert(uniqueItems().local, timeStamp: Date()) { _ in
			completedOperationsInOrder.append(op3)
			op3.fulfill()
		}

		waitForExpectations(timeout: 5.0)

		XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order", file: file, line: line)
	}

	@discardableResult
	func deleteCache(from sut: FeedStore) -> Error? {
		let exp = expectation(description: "wait to complete")
		var deletedError: Error?
		sut.deleteCacheFeed { deletionError in
			deletedError = deletionError
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
		return deletedError
	}

	@discardableResult
	func insert(_ cache: (feed: [LocalFeedImage], timeStamp: Date), to sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wating to complete")
		var insertedError: Error?
		sut.insert(cache.feed, timeStamp: cache.timeStamp) { insertionError in
			insertedError = insertedError
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
		return insertedError
	}

	func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
		expect(sut, toRetrieve: expectedResult, file: file, line: line)
		expect(sut, toRetrieve: expectedResult, file: file, line: line)
	}

	func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCacheFeedResult, file: StaticString = #file, line: UInt = #line) {
		let exp = expectation(description: "Wait for completion")

		sut.retrieve { retriveResult in
			switch (retriveResult, expectedResult) {
			case (.empty, .empty), (.failure, .failure):
				break
			case let (.found(retriveFeed, retriveTime), .found(expectedFeed, expectedTime)):
				XCTAssertEqual(retriveFeed, expectedFeed, file: file, line: line)
				XCTAssertEqual(retriveTime, expectedTime, file: file, line: line)

			default:
				XCTFail("Expected to retrieve \(expectedResult), got \(retriveResult) instead", file: file, line: line)
			}

			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
	}
}
