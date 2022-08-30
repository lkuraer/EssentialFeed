//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Ruslan Sabirov on 23.08.2022.
//

import Foundation

public enum RetreivalCompletionResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(error: Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)
    typealias RetreivalCompletion = ((RetreivalCompletionResult) -> Void)

    func deleteCache(completion: @escaping DeletionCompletion)
    func insert(items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retreive(completion: @escaping RetreivalCompletion)
}

