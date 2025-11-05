////
//// Copyright © Essential Developer. All rights reserved.
////
//
//import XCTest
//
//@testable import FeedAPIChallenge
//
//final class CacheFeedFromLocalUseCaseTests: XCTestCase {
//
//	func test_init_doesNotDetailCacheWhenCreated() {
//		let (_, store) = makeSut()
//		XCTAssertEqual(store.receivedMessages.count, 0)
//	}
//
//	func test_save_requestCacheDeletion() {
//		let (sut, store) = makeSut()
//		let items = uniqueItems()
//
//		sut.save(items.models) { _ in }
//
//		XCTAssertEqual(store.receivedMessages, [.deletedCacheFeed])
//	}
//
//	func test_save_doseNotRequestCacheDeletionOnDeletionError() {
//		let (sut, store) = makeSut()
//		let items = uniqueItems()
//		let deletionError = anyNSError()
//		sut.save(items.models) { _ in }
//		store.completeWithDeletion(with: deletionError)
//
//		XCTAssertEqual(store.receivedMessages, [.deletedCacheFeed])
//	}
//
//	func test_save_requestNewCacheInsertionWithTimestamp() {
//		let timepStamp = Date()
//		let (sut, store) = makeSut {
//			timepStamp
//		}
//		let items = uniqueItems()
//		sut.save(items.models) { _ in }
//		store.completeDeletionSuccessfully()
//		XCTAssertEqual(store.receivedMessages, [.deletedCacheFeed, .insert(items.local, timepStamp)])
//	}
//
//	func test_save_failOnDeletionError() {
//		let timepStamp = Date()
//		let (sut, store) = makeSut {
//			timepStamp
//		}
//		expect(sut, toCompleteWithEroor: anyNSError()) {
//			store.completeWithDeletion(with: anyNSError())
//		}
//	}
//
//	func test_save_failsOnInsertionError() {
//		let (sut, store) = makeSut()
//		expect(sut, toCompleteWithEroor: anyNSError()) {
//			store.completeDeletionSuccessfully()
//			store.completeWithInsertion(with: anyNSError())
//		}
//	}
//
//	func test_save_succeedsOnSuccessfulCacheInsertion() {
//		let (sut, store) = makeSut()
//		expect(sut, toCompleteWithEroor: nil) {
//			store.completeDeletionSuccessfully()
//			store.completeInsertionSuccessfully()
//		}
//	}
//
//	func test_save_doesNotDeliverInsertionErrorAfterSUTBeenDeallocated() {
//		let store = FeedStoreSpy()
//		let currentDate: () -> Date = { Date() }
//		var sut: LocalFeedLoader? = LocalFeedLoader(store, currentDate: currentDate)
//
//		var receivedErrors = [LocalFeedLoader.SaveResult]()
//		sut?.save(uniqueItems().models) { error in
//			receivedErrors.append(error)
//		}
//		store.completeDeletionSuccessfully()
//		sut = nil
//		store.completeWithInsertion(with: anyNSError())
//
//		XCTAssertEqual(receivedErrors.count, 0)
//	}
//
//	func test_save_doesNotDeveliverDeleteErrorAfterSUTDeallocated() {
//		let store = FeedStoreSpy()
//		var sut: LocalFeedLoader? = LocalFeedLoader(store, currentDate: Date.init)
//		var receivedError = [LocalFeedLoader.SaveResult]()
//
//		sut?.save(uniqueItems().models) { error in
//			receivedError.append(error)
//		}
//		sut = nil
//		store.completeWithDeletion(with: anyNSError())
//		XCTAssertEqual(receivedError.count, 0)
//	}
//
//	// MARK: - Helpers
//
//	private func expect(_ sut: LocalFeedLoader, toCompleteWithEroor expectedError: Error?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
//		let exp = expectation(description: "Wait for save completion")
//		var receivedError: LocalFeedLoader.SaveResult?
//		sut.save(uniqueItems().models) { error in
//			receivedError = error
//			exp.fulfill()
//		}
//		action()
//		wait(for: [exp], timeout: 1.0)
//		XCTAssertEqual(receivedError as? NSError?, expectedError as? NSError)
//	}
//
//	private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
//		let store = FeedStoreSpy()
//		let sut = LocalFeedLoader(store, currentDate: currentDate)
//		trackForMemoryLeaks(store, file: file, line: line)
//		trackForMemoryLeaks(sut, file: file, line: line)
//		return (sut, store)
//	}
//}
