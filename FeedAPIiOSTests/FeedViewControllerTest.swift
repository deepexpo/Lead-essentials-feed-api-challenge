//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge
@testable import FeedAPIiOS

final class FeedViewControllerTest: XCTestCase {
	func test_loadFeedActions_requestFeedFromLoader() {
		let (loader, sut) = makeSUT()
		XCTAssertEqual(loader.loadCallCount, 0)

		sut.loadViewIfNeeded()
		XCTAssertEqual(loader.loadCallCount, 1)

		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 2)

		sut.refreshControl?.simulatePullToRefresh()
		XCTAssertEqual(loader.loadCallCount, 3)
	}

	func test_loadingIndicator_isVisibleWhileLoadingFeed() {
		let (loader, sut) = makeSUT()
		sut.simulateAppearance()

		sut.beginRefreshing()
		XCTAssertEqual(sut.isShowingLoadingIndicator, true)

		loader.completeFeedLoading(at: 0)
		XCTAssertEqual(sut.isShowingLoadingIndicator, false)

		sut.simulateUserInitiatedReload()
		XCTAssertEqual(sut.isShowingLoadingIndicator, true)

		loader.completeWithError(at: 1)
		XCTAssertEqual(sut.isShowingLoadingIndicator, false)
	}

	func test_loadFeedCompletion_renderSuccessfullyLoadFeed() {
		let image1 = makeImage(description: "a description", location: "a location")
		let image2 = makeImage(description: nil, location: "a location")
		let image3 = makeImage(description: "a description", location: nil)
		let image4 = makeImage(description: nil, location: nil)
		let (loader, sut) = makeSUT()

		sut.simulateAppearance()
		XCTAssertEqual(sut.numberOfRows(in: 0), 0)

		loader.completeFeedLoading(with: [image1], at: 0)
		XCTAssertEqual(sut.numberOfRows(in: 0), 1)
		assert(sut, hasViewConfiguredFor: image1, at: 0)
		sut.simulateUserInitiatedReload()
		loader.completeFeedLoading(with: [image1, image2, image3, image4], at: 1)
		XCTAssertEqual(sut.numberOfRows(in: 0), 4)
		assert(sut: sut, isRendering: [image1, image2, image3, image4])
	}

	func test_loadFeedCompletion_doesNotAlterCurrentRenderingOnError() {
		let image1 = makeImage(description: "a description", location: "a location")
		let (loader, sut) = makeSUT()
		sut.simulateAppearance()
		loader.completeFeedLoading(with: [image1], at: 0)
		assert(sut: sut, isRendering: [image1])

		sut.simulateUserInitiatedReload()
		loader.completeWithError(at: 1)
		assert(sut: sut, isRendering: [image1])
	}

	func test_feedImageView_loadImageURLWhenVisibile() {
		let image_0 = makeImage(url: URL(string: "http://url1-0.com")!)
		let image_1 = makeImage(url: URL(string: "http://url1-0.com")!)
		let (loader, sut) = makeSUT()
		sut.simulateAppearance()
		loader.completeFeedLoading(with: [image_0, image_1], at: 0)

		XCTAssertEqual(loader.loadImageURLs, [])

		sut.simulateFeedImageViewVisible(at: 0)
		XCTAssertEqual(loader.loadImageURLs, [image_0.url])
		sut.simulateFeedImageViewVisible(at: 1)
		XCTAssertEqual(loader.loadImageURLs, [image_0.url, image_1.url])
	}

	func test_feedImageView_cancelLoadImageURLWhenNotVisibile() {
		let image_0 = makeImage(url: URL(string: "http://url1-0.com")!)
		let image_1 = makeImage(url: URL(string: "http://url1-0.com")!)
		let (loader, sut) = makeSUT()
		sut.simulateAppearance()
		loader.completeFeedLoading(with: [image_0, image_1], at: 0)

		XCTAssertEqual(loader.loadImageURLs, [])

		sut.simulateFeedImageViewNotVisible(at: 0)
		XCTAssertEqual(loader.cancelledImageURLs, [image_0.url])
		sut.simulateFeedImageViewNotVisible(at: 1)
		XCTAssertEqual(loader.cancelledImageURLs, [image_0.url, image_1.url])
	}

	//Helper

	func makeSUT(file: StaticString = #file, line: UInt = #line) -> (LoaderSpy, FeedViewController) {
		let loader = LoaderSpy()
		let sut = FeedViewController(loader: loader, imageDataLoader: loader)
		trackForMemoryLeaks(loader)
		trackForMemoryLeaks(sut)
		return (loader, sut)
	}

	func assert(sut: FeedViewController, isRendering feeds: [FeedImage], file: StaticString = #file, line: UInt = #line) {
		guard sut.numberOfRows(in: 0) == feeds.count else {
			return XCTFail("Expected \(feeds.count) images, got \(sut.numberOfRows(in: 0)) instead.", file: file, line: line)
		}
		feeds.enumerated().forEach { index, image in
			assert(sut, hasViewConfiguredFor: image, at: index)
		}
	}

	func assert(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
		let view = sut.cell(row: index, section: 0)
		guard let cell = view as? FeedImageCell else {
			return XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
		}
		let shouldLocationBeVisible = (image.location != nil)
		XCTAssertEqual(cell.isShowingLocation, shouldLocationBeVisible)
		XCTAssertEqual(cell.descriptionText, image.description)
		XCTAssertEqual(cell.locationText, image.location)
	}

	func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "http://google.com")!, file: StaticString = #file, line: UInt = #line) -> FeedImage {
		return FeedImage(id: UUID(), description: description, location: location, url: URL(string: "http://google.com")!)
	}

	class LoaderSpy: FeedLoader, FeedImageDataLoader {
		//MARKS : FeedLoader

		private var completions = [(FeedLoader.Result) -> Void]()

		func load(completion: @escaping (FeedLoader.Result) -> Void) {
			completions.append(completion)
		}

		func completeFeedLoading(with images: [FeedImage] = [], at index: Int = 0) {
			completions[index](.success(images))
		}

		func completeWithError(at index: Int = 0) {
			let error = NSError(domain: "any error", code: 0)
			completions[index](.failure(error))
		}

		var loadCallCount: Int {
			return completions.count
		}

		// Mark :FeedImageDataLoader

		private(set) var loadImageURLs = [URL]()
		private(set) var cancelledImageURLs = [URL]()

		func loadImageData(from url: URL) {
			loadImageURLs.append(url)
		}

		func cancelImageDataLoad(from url: URL) {
			cancelledImageURLs.append(url)
		}
	}
}

private extension UIRefreshControl {
	func simulatePullToRefresh() {
		allTargets.forEach { target in
			actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
				(target as NSObject).perform(Selector($0))
			}
		}
	}
}

private extension FeedViewController {
	func simulateAppearance() {
		if !isViewLoaded {
			loadViewIfNeeded()
			prepareForFirstAppearance()
		}

		beginAppearanceTransition(true, animated: false)
		endAppearanceTransition()
	}

	private func prepareForFirstAppearance() {
		setSmallFrameToPreventRenderingCells()
		replaceRefreshControlWithFakeForiOS17PlusSupport()
	}

	private func setSmallFrameToPreventRenderingCells() {
		tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 1)
	}

	private func replaceRefreshControlWithFakeForiOS17PlusSupport() {
		let fakeRefreshControl = FakeUIRefreshControl()

		refreshControl?.allTargets.forEach { target in
			refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
				fakeRefreshControl.addTarget(target, action: Selector(action), for: .valueChanged)
			}
		}

		refreshControl = fakeRefreshControl
	}

	private class FakeUIRefreshControl: UIRefreshControl {
		private var _isRefreshing = false

		override var isRefreshing: Bool { _isRefreshing }

		override func beginRefreshing() {
			_isRefreshing = true
		}

		override func endRefreshing() {
			_isRefreshing = false
		}
	}

	func simulateUserInitiatedReload() {
		refreshControl?.simulatePullToRefresh()
	}

	var isShowingLoadingIndicator: Bool {
		return refreshControl?.isRefreshing == true
	}

	func beginRefreshing() {
		refreshControl?.beginRefreshing()
	}

	func endRefreshing() {
		refreshControl?.endRefreshing()
	}

	func simulateFeedImageViewVisible(at index: Int) {
		_ = cell(row: index, section: 0)
	}

	func simulateFeedImageViewNotVisible(at row: Int) {
		let view = cell(row: row, section: 0)
		let delegate = tableView.delegate
		let index = IndexPath(row: row, section: 0)
		delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
	}

	func numberOfRows(in section: Int) -> Int {
		tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
	}

	func cell(row: Int, section: Int) -> UITableViewCell? {
		guard numberOfRows(in: section) > row else {
			return nil
		}
		let ds = tableView.dataSource
		let index = IndexPath(row: row, section: section)
		return ds?.tableView(tableView, cellForRowAt: index)
	}
}

private extension FeedImageCell {
	var isShowingLocation: Bool {
		return !locationView.isHidden
	}

	var locationText: String? {
		return locationLabel.text
	}

	var descriptionText: String? {
		return descriptionLabel.text
	}
}
