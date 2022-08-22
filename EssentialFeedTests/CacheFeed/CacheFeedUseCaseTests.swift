//
//  CacheFeedTests.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 19.08.2022.
//

import Foundation
import XCTest
import EssentialFeed

class LocalFeedLoader {
    var store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        self.store.deleteCache()
    }
}

class FeedStore {
    var deleteCacheFeedCallCount: Int = 0
    
    func deleteCache() {
        deleteCacheFeedCallCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let (store, sut) = makeSUT()
        
        let items = [uniqueItem(), uniqueItem()]
        sut.save(items)
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 1)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (store, sut)
    }
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://any-url.com")!)
    }
    
}
