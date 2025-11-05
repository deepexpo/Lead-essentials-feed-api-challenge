//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit
internal import FeedAPIChallenge

final class FeedViewController: UITableViewController {
	var loader: FeedLoader?

	public convenience init(loader: FeedLoader) {
		self.init()
		self.loader = loader
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
		self.load()
	}

	@objc private func load() {
		self.refreshControl?.beginRefreshing()
		loader?.load { [weak self] _ in
			self?.refreshControl?.endRefreshing()
		}
	}
}
