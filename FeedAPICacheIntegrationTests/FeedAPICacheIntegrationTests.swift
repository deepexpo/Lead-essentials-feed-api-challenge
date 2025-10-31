//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

final class FeedAPICacheIntegrationTests: XCTestCase {
	override func setUp() {
		super.setUp()
		setupEmptyStoreState()
	}

	override func tearDown() {
		super.tearDown()
		undoStoreSideEffects()
	}

	func test_load_deliversNoItemOnEmptyCache() {
		let sut = makeSUT()
		let exp = expectation(description: "wait for competion")

		sut.load { result in
			switch (result) {
			case let .success(imageFeed):
				XCTAssertEqual(imageFeed, [], "Expected Empty Feed")
			case let .failure(error):
				XCTFail("Expected success but got failure \(error) instead")
			}
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1.0)
	}

	func test_load_deliversItemsSavedOnASeparateInstance() {
		let sutToPerformSave = makeSUT()
		let sutToPerformLoad = makeSUT()
		let feed = uniqueItems().models

		let saveExp = expectation(description: "Wait for save completion")
		sutToPerformSave.save(feed) { saveResult in
			if case let Result.failure(saveError) = saveResult {
				XCTAssertNil(saveError, "Expected to save feed successfully")
			}
			saveExp.fulfill()
		}
		wait(for: [saveExp], timeout: 1.0)

		let loadExp = expectation(description: "Wait for load completion")
		sutToPerformLoad.load { loadResult in
			switch loadResult {
			case let .success(imageFeed):
				XCTAssertEqual(imageFeed, feed)

			case let .failure(error):
				XCTFail("Expected successful feed result, got \(error) instead")
			}

			loadExp.fulfill()
		}
		wait(for: [loadExp], timeout: 1.0)
	}

	//Helper

	func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
		let storeUrl = testSpecificStoreURL()
		let storeBundle = Bundle(for: CoreDataFeedStore.self)
		let coreDataStore = try! CoreDataFeedStore(storeURL: storeUrl, bundle: storeBundle)
		let sut = LocalFeedLoader(coreDataStore, currentDate: Date.init)
		trackForMemoryLeaks(coreDataStore, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func testSpecificStoreURL() -> URL {
		return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
	}

	private func cachesDirectory() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
	}

	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}

	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}

	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL())
	}
}
