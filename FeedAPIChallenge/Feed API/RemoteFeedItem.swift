//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
	let id: UUID
	let description: String?
	let location: String?
	let url: URL
}
