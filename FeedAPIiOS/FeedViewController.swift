//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit
internal import FeedAPIChallenge

public protocol FeedImageDataLoaderTask {
	func cancel()
}

protocol FeedImageDataLoader {
	typealias Result = Swift.Result<Data, Error>
	func loadImageData(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageDataLoaderTask
}

final class FeedViewController: UITableViewController {
	var loader: FeedLoader?
	var imageLoader: FeedImageDataLoader?

	var tableViewModel: [FeedImage] = .init()

	var tasks: [IndexPath: FeedImageDataLoaderTask] = .init()

	public convenience init(loader: FeedLoader, imageDataLoader: FeedImageDataLoader) {
		self.init()
		self.loader = loader
		self.imageLoader = imageDataLoader
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
		self.load()
	}

	@objc private func load() {
		self.refreshControl?.beginRefreshing()
		loader?.load { [weak self] result in
			if let feed = (try? result.get()) {
				self?.tableViewModel = feed
				self?.tableView.reloadData()
			}
			self?.refreshControl?.endRefreshing()
		}
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
		tasks[indexPath]?.cancel()
		tasks[indexPath] = nil
	}
}
