//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit
internal import FeedAPIChallenge

protocol FeedImageDataLoader {
	func loadImageData(from url: URL)
	func cancelImageDataLoad(from url: URL)
}

final class FeedViewController: UITableViewController {
	var loader: FeedLoader?
	var imageLoader: FeedImageDataLoader?

	var tableViewModel: [FeedImage] = .init()

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
		imageLoader?.loadImageData(from: model.url)
		return cell
	}

	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let model = tableViewModel[indexPath.row]
		imageLoader?.cancelImageDataLoad(from: model.url)
	}
}
