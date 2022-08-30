//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 26.08.2022.
//

import Foundation
import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetreival() {
        let (store, sut) = makeSUT()
        
        sut.load { _ in }
        XCTAssertEqual(store.receivedMessages, [.retreive])
    }
    
    func test_load_requestCacheErrorOnRetreival() {
        let (store, sut) = makeSUT()
        let expectedError: NSError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(expectedError)) {
            store.completeRetreival(with: expectedError)
        }
    }

    func test_load_requestCacheCompletesWithEmptyArray() {
        let (store, sut) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completesWithEmptyArray()
        }
    }
    
    func test_load_requestCacheCompletesWhenDateIsValid() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let lessThanSevenDays = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetreival(with: feed.locals, timestamp: lessThanSevenDays)
        }
    }
    
    func test_load_requestCacheCompletesEmptyArrayWhenDateIsNotValid() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let lessThanSevenDays = fixedCurrentDate.adding(days: -7)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetreival(with: feed.locals, timestamp: lessThanSevenDays)
        }
    }
    
    func test_load_requestCacheCompletesEmptyArrayWhenDateIsMoreThanSevenDays() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let moreThanSevenDays = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetreival(with: feed.locals, timestamp: moreThanSevenDays)
        }
    }
    
    private func expect(_ sut: CacheFeedLoader, toCompleteWith expectedResult: CacheFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for result")
    
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got received result instead \(receivedResult)")
            }
            exp.fulfill()
        }
        action()

        wait(for: [exp], timeout: 1.0)
    }

    // Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: CacheFeedLoader) {
        let store = FeedStoreSpy()
        let sut = CacheFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (store, sut)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://any-url.com")!)
    }
    
    private func uniqueItems() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let items = [uniqueItem(), uniqueItem()]
        let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
        return (items, localItems)
    }


}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
