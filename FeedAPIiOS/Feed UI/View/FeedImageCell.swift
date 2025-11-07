//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

public final class FeedImageCell: UITableViewCell {
	var locationLabel = UILabel()
	var locationView = UIView()
	var descriptionLabel = UILabel()
	var feedImageView = UIImageView()
	var feedImageContainer = UIView()

	private(set) public lazy var retryButtonView: UIButton = {
		let button = UIButton()
		button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
		return button
	}()

	var onRetry: (() -> Void)?

	@objc private func retryButtonTapped() {
		onRetry?()
	}
}
