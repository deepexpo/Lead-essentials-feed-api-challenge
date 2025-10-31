//
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

final class RemoteFeedItemMapper {
	private init() {}
	static let OK_HTTP_STATUS_CODE: Int = 200

	private struct RootNote: Decodable {
		let items: [FeedApiItem]
		let remoteItems: [RemoteFeedItem]

		var feedItems: [FeedImage] {
			return items.map(\.self.feedImage)
		}
	}

	private struct FeedApiItem: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		var feedImage: FeedImage {
			return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
		}
	}

//	static func map(_ fromData: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
//		guard response.statusCode == OK_HTTP_STATUS_CODE, let rootNode = try? JSONDecoder().decode(RootNote.self, from: fromData) else {
//			return .failure(RemoteFeedLoader.Error.invalidData)
//		}
//		return .success(rootNode.feedItems)
//	}

	static func map(_ fromData: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
		guard response.statusCode == OK_HTTP_STATUS_CODE, let rootNode = try? JSONDecoder().decode(RootNote.self, from: fromData) else {
			throw RemoteFeedLoader.Error.invalidData
		}
		return rootNode.remoteItems
	}
}
