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
    var currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        self.store.deleteCache { [unowned self] error in
            if error == nil {
                self.store.insert(items: items, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    
    var deleteCacheFeedCallCount: Int = 0
    var insertCallCount: Int = 0
    
    var deletionCompletions = [DeletionCompletion]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    func deleteCache(completion: @escaping DeletionCompletion) {
        deleteCacheFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionOnSuccess(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertions.append((items, timestamp))
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.deleteCacheFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT()
        
        sut.save(items)
        
        XCTAssertEqual(store.deleteCacheFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestSaveIfDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT()
        
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_doesRequestSaveOnSuccessDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT()
        
        sut.save(items)
        store.completeDeletionOnSuccess()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }

    func test_save_doesRequestSaveWithTimestampOnSuccessDeletion() {
        let timestamp_1 = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT(currentDate: { timestamp_1 })
        
        sut.save(items)
        store.completeDeletionOnSuccess()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp_1)
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (store, sut)
    }
    
    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://any-url.com")!)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

}
