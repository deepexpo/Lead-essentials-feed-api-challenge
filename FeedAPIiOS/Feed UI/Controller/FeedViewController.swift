//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit
internal import FeedAPIChallenge

public final class FeedRefreshViewController: NSObject {
	var feedLoader: FeedLoader?
	init(feedLoader: FeedLoader? = nil) {
		self.feedLoader = feedLoader
	}

	public lazy var view: UIRefreshControl = {
		let view = UIRefreshControl()
		view.addTarget(self, action: #selector(refresh), for: .valueChanged)
		return view
	}()

	var onRefresh: (([FeedImage]) -> Void)?
	@objc func refresh() {
		self.view.beginRefreshing()
		feedLoader?.load { [weak self] result in
			if let feed = (try? result.get()) {
				self?.onRefresh?(feed)
			}
			self?.view.endRefreshing()
		}
	}
}

final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
	public var refreshController: FeedRefreshViewController?
	var imageLoader: FeedImageDataLoader?

	var tableViewModel = [FeedImage]() {
		didSet {
			tableView.reloadData()
		}
	}

	var tasks: [IndexPath: FeedImageDataLoaderTask] = .init()

	public convenience init(loader: FeedLoader, imageDataLoader: FeedImageDataLoader) {
		self.init()
		self.refreshController = FeedRefreshViewController(feedLoader: loader)
		self.imageLoader = imageDataLoader
		self.tableView.prefetchDataSource = self
	}

	private var onViewDidAppear: ((FeedViewController) -> Void)?

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.refreshControl = refreshController?.view

		refreshController?.onRefresh = { [weak self] feed in
			self?.tableViewModel = feed
		}
		onViewDidAppear = { vc in
			vc.onViewDidAppear = nil
			vc.refreshController?.refresh()
		}
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		onViewDidAppear?(self)
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tableViewModel.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let model = tableViewModel[indexPath.row]
		let cell = FeedImageCell()
		cell.descriptionLabel.text = model.description
		cell.locationLabel.text = model.location
		cell.locationView.isHidden = model.location == nil
		cell.feedImageView.image = nil
		cell.retryButtonView.isHidden = true
		cell.feedImageContainer.startShimmering()
		let loadImage = { [weak self, weak cell] in
			guard self == self else { return }
			self?.tasks[indexPath] = self?.imageLoader?.loadImageData(from: model.url) { [weak cell] result in
				let data = try? result.get()
				let image = data.map(UIImage.init) ?? nil
				cell?.feedImageView.image = image
				cell?.retryButtonView.isHidden = (image != nil)
				cell?.feedImageContainer.stopShimmering()
			}
		}
		loadImage()
		cell.onRetry = loadImage
		return cell
	}

	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cancelTask(at: indexPath)
	}

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		startTask(at: indexPath)
	}

	func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
		indexPaths.forEach(startTask)
	}

	public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
		indexPaths.forEach(cancelTask)
	}

	private func cancelTask(at indexPath: IndexPath) {
		tasks[indexPath]?.cancel()
		tasks[indexPath] = nil
	}

	private func startTask(at indexPath: IndexPath) {
		let model = tableViewModel[indexPath.row]
		self.tasks[indexPath] = imageLoader?.loadImageData(from: model.url) { _ in }
	}
}
