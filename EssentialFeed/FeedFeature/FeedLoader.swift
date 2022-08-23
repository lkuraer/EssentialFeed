//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ruslan Sabirov on 27.07.2022.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

