//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ruslan Sabirov on 27.07.2022.
//

import Foundation

public enum FeedLoadResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (FeedLoadResult) -> Void)
}

