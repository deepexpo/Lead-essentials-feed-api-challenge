//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func test_init_doesNotMessageUponsStoreCreation() {
		let (_, store) = makeSut()
		XCTAssertEqual(store.receivedMessages.count, 0)
	}

	func test_load_requestCacheRetrivel() {
		let (sut, store) = makeSut()
		sut.load { _ in }
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_failsOnRetrievalError() {
		let (sut, store) = makeSut()
		expect(sut, toCompleteWith: .failure(anyNSError())) {
			store.completeRetrive(with: anyNSError())
		}
	}

	func test_load_deliversNoImagesOnEmptyCache() {
		let (sut, store) = makeSut()
		expect(sut, toCompleteWith: .success([])) {
			store.completeRetrievalWithEmptyCache()
		}
	}

	func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
		let feed = uniqueItems()
		let fixedCurrentDate = Date()
		let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		expect(sut, toCompleteWith: .success(feed.models), when: {
			store.completeRetriveSuccessfully(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
		})
	}

	func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
		let feed = uniqueItems()
		let fixedCurrentDate = Date()
		let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

		expect(sut, toCompleteWith: .success([]), when: {
			store.completeRetriveSuccessfully(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
		})
	}

	func test_load_hasNoSideEffectsOnRetrievalError() {
		let (sut, store) = makeSut()

		sut.load { _ in
		}

		store.completeRetrive(with: anyNSError())
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnEmptyCache() {
		let (sut, store) = makeSut()
		sut.load { _ in }
		store.completeRetrievalWithEmptyCache()

		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache() {
		let feeds = uniqueItems()
		let fixedCurrentDate = Date()
		let lessthanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
		sut.load { _ in
		}
		store.completeRetriveSuccessfully(with: feeds.local, timestamp: lessthanSevenDaysOldTimeStamp)
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnSevenDaysOldCache() {
		let feeds = uniqueItems()
		let fixedCurrentDate = Date()
		let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
		sut.load { _ in
		}
		store.completeRetriveSuccessfully(with: feeds.local, timestamp: sevenDaysOldTimeStamp)
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_hasNoSideEffectsOnMoreThanSevenDaysOldCache() {
		let feeds = uniqueItems()
		let fixedCurrentDate = Date()
		let moreThansevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(days: -1)
		let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
		sut.load { _ in
		}
		store.completeRetriveSuccessfully(with: feeds.local, timestamp: moreThansevenDaysOldTimeStamp)
		XCTAssertEqual(store.receivedMessages, [.retrieve])
	}

	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
		let store = FeedStoreSpy()
		var sut: LocalFeedLoader? = LocalFeedLoader(store, currentDate: Date.init)
		var reveivedRestule = [LocalFeedLoader.LoadResult]()

		sut?.load { result in
			reveivedRestule.append(result)
		}

		sut = nil
		store.completeRetrievalWithEmptyCache()
		XCTAssertEqual(reveivedRestule.count, 0)
	}

	//Helpers

	private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
		let exp = expectation(description: "Wait for load compeltion")

		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedImages), .success(expectedImages)):
				XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
			case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			default:
				XCTFail("Expected empty images got \(receivedResult) instead")
			}
			exp.fulfill()
		}
		action()
		wait(for: [exp], timeout: 1.0)
	}

	private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
		let store = FeedStoreSpy()
		let sut = LocalFeedLoader(store, currentDate: currentDate)
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, store)
	}
}
