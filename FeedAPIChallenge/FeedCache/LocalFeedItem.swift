//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

public struct LocalFeedImage: Equatable {
	let id: UUID
	let desciption: String?
	let location: String?
	let url: URL

	init(id: UUID, desciption: String?, location: String?, url: URL) {
		self.id = id
		self.desciption = desciption
		self.location = location
		self.url = url
	}
}
