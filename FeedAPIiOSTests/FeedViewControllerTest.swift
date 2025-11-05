//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import FeedAPIChallenge

class FeedViewController: UITableViewController {
	var loader: FeedLoader?

	convenience init(loader: FeedViewControllerTest.LoaderSpy) {
		self.init()
		self.loader = loader
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
		self.load()
	}

	override func viewWillAppear(_ animated: Bool) {}

	@objc private func load() {
		self.refreshControl?.beginRefreshing()
		loader?.load { [weak self] _ in
			self?.refreshControl?.endRefreshing()
		}
	}
}

final class FeedViewControllerTest: XCTestCase {
	
	func test_init_doesNotLoadFeed() {
		let (loader, _) = makeSUT()

		XCTAssertEqual(loader.loadCallCount, 0)
	}

	func test_viewDidLoad_loadFeed() {
		let (loader, sut) = makeSUT()

		sut.loadViewIfNeeded()

		XCTAssertEqual(loader.loadCallCount, 1)
	}

	func test_userInitiatedFeedReload_reloadsFeed() {
		let (loader, sut) = makeSUT()
		sut.loadViewIfNeeded()
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(loader.loadCallCount, 2)

		sut.refreshControl?.simulatePullToRefresh()
		XCTAssertEqual(loader.loadCallCount, 3)
	}

	func test_viewDidLoad_showLoadingIndicator() {
		let (_, sut) = makeSUT()
		sut.simulateAppearance()
		sut.beginRefreshing()
		XCTAssertEqual(sut.isShowingLoadingIndicator, true)
	}

	func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
		let (loader, sut) = makeSUT()
		sut.simulateAppearance()
		sut.beginRefreshing()
		loader.completeFeedLoading()
		XCTAssertEqual(sut.isShowingLoadingIndicator, false)
	}

	func test_userInitiatedFeedReload_showsLoadingIndicator() {
		let (_, sut) = makeSUT()
		sut.simulateAppearance()
		sut.simulateUserInitiatedReload()
		XCTAssertEqual(sut.isShowingLoadingIndicator, true)
	}

	func test_userInitiatedFeedReload_hidesLoadingIndicatorOnLoaderCompletion() {
		let (loader, sut) = makeSUT()
		sut.simulateAppearance()
		sut.simulateUserInitiatedReload()
		loader.completeFeedLoading()
		XCTAssertEqual(sut.isShowingLoadingIndicator, false)
	}

	//Helper

	func makeSUT(file: StaticString = #file, line: UInt = #line) -> (LoaderSpy, FeedViewController) {
		let loader = LoaderSpy()
		let sut = FeedViewController(loader: loader)
		trackForMemoryLeaks(loader)
		trackForMemoryLeaks(sut)
		return (loader, sut)
	}

	class LoaderSpy: FeedLoader {
		private var completions = [(FeedLoader.Result) -> Void]()

		func load(completion: @escaping (FeedLoader.Result) -> Void) {
			completions.append(completion)
		}

		func completeFeedLoading() {
			completions[0](.success([]))
		}

		var loadCallCount: Int {
			return completions.count
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
