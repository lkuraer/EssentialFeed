//
//  CacheFeedTests.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 19.08.2022.
//

import Foundation
import XCTest
import EssentialFeed


class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        let (store, sut) = makeSUT()
        
        sut.save(uniqueItems().models) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestSaveIfDeletionError() {
        let (store, sut) = makeSUT()
        
        let deletionError = anyNSError()
        
        sut.save(uniqueItems().models) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesRequestSaveWithTimestampOnSuccessDeletion() {
        let timestamp_1 = Date()
        let items = uniqueItems()
        
        let (store, sut) = makeSUT(currentDate: { timestamp_1 })
        
        sut.save(items.models) { _ in }
        store.completeDeletionOnSuccess()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items.locals, timestamp_1)])
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
        
        var receivedResults = [CacheFeedLoader.SaveResult]()
        sut?.save(uniqueItems().models) { receivedResults.append($0) }
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_abortSavingAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: CacheFeedLoader? = CacheFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [CacheFeedLoader.SaveResult]()
        sut?.save(uniqueItems().models) { receivedResults.append($0) }
        
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
    
    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://any-url.com")!)
    }
    
    private func uniqueItems() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let items = [uniqueItem(), uniqueItem()]
        let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
        return (items, localItems)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
}
