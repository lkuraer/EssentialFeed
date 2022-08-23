//
//  CacheFeedTests.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 19.08.2022.
//

import Foundation
import XCTest
import EssentialFeed

class CacheFeedLoader {
    var store: FeedStore
    var currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        self.store.deleteCache { [weak self] error in
            guard let self = self else { return }
            
            if let deletionError = error {
                completion(deletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items: items, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)

    func deleteCache(completion: @escaping DeletionCompletion)
    func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestSaveIfDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT()
        
        let deletionError = anyNSError()
        
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesRequestSaveWithTimestampOnSuccessDeletion() {
        let timestamp_1 = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (store, sut) = makeSUT(currentDate: { timestamp_1 })
        
        sut.save(items) { _ in }
        store.completeDeletionOnSuccess()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items, timestamp_1)])
    }
    
    func test_save_failsOnDeletionError() {
        let (store, sut) = makeSUT()
        
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (store, sut) = makeSUT()
        
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionOnSuccess()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_insertionSuccessfull() {
        let (store, sut) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            store.completeDeletionOnSuccess()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_abortDeletionAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: CacheFeedLoader? = CacheFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()]) { receivedResults.append($0) }
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_abortSavingAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: CacheFeedLoader? = CacheFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [Error?]()
        sut?.save([uniqueItem()]) { receivedResults.append($0) }
        
        store.completeDeletionOnSuccess()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }

    private func expect(_ sut: CacheFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let items = [uniqueItem(), uniqueItem()]
        
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as? NSError, expectedError)
    }

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: CacheFeedLoader) {
        let store = FeedStoreSpy()
        let sut = CacheFeedLoader(store: store, currentDate: currentDate)
        
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
    
    private class FeedStoreSpy: FeedStore {
        var deletionCompletions = [DeletionCompletion]()
        var insertionCompletions = [InsertionCompletion]()
        
        var receivedMessages = [ReceivedMessage]()
        
        enum ReceivedMessage: Equatable {
            case deleteCacheFeed
            case insert([FeedItem], Date)
        }
        
        func deleteCache(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCacheFeed)
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionOnSuccess(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func insert(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
