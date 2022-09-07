//
//  CacheFeedLoader.swift
//  EssentialFeed
//
//  Created by Ruslan Sabirov on 23.08.2022.
//

import Foundation

private final class CachePolicy {
    init() {}
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxDays: Int {
        return 7
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxAge = calendar.date(byAdding: .day, value: maxDays, to: timestamp) else {
            return false
        }
        
        return date < maxAge
    }
}

public final class CacheFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
}

extension CacheFeedLoader {
    public typealias SaveResult = Error?

    public func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        self.store.deleteCache { [weak self] error in
            guard let self = self else { return }
            
            if let deletionError = error {
                completion(deletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }

    private func cache(_ items: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items: items.toLocals(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension CacheFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retreive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, timestamp) where CachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension CacheFeedLoader {
    public func validateCache() {
        store.retreive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCache(completion: { _ in })
            case let .found(_, timestamp) where !CachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCache(completion: { _ in })
            case .empty, .found:
                break
            }
        }
    }
}

extension Array where Element == FeedImage {
    func toLocals() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}

extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    }
}
