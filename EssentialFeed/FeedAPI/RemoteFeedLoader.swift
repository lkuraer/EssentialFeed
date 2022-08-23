//
//  RemoteFeedLoader.swift
//  EssentialFeed (iOS)
//
//  Created by Ruslan Sabirov on 01.08.2022.
//

import Foundation


public final class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient!
    private let url: URL!
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult

    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else {
                return
            }
            
            switch result {
            case .success(let data, let response):
                completion(RemoteFeedLoader.map(data, from: response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemMapper.map(data, from: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedItem] {
        return map { FeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.image) }
    }
}
