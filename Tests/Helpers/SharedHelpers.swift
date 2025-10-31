//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation
@testable import FeedAPIChallenge

func anyNSError() -> NSError {
	return NSError(domain: "any error", code: 0)
}

func uniqueItem() -> FeedImage {
	return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueItems() -> (models: [FeedImage], local: [LocalFeedImage]) {
	let models = [uniqueItem(), uniqueItem()]
	let locals = models.map { LocalFeedImage(id: $0.id, desciption: $0.description, location: $0.location, url: $0.url) }
	return (models, locals)
}

func anyURL() -> URL {
	return URL(string: "http://any-url.com")!
}

extension Date {
	func adding(days: Int) -> Date {
		return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
	}

	func adding(seconds: TimeInterval) -> Date {
		return self + seconds
	}
}
