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
    
    func test_load_hasNoSideEffectsOnRetreivalError() {
        let (store, sut) = makeSUT()
        
        sut.load { _ in }
        store.completeRetreival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_load_hasNoSideEffectsWhenCacheIsEmpty() {
        let (store, sut) = makeSUT()
        
        sut.load { _ in }
        store.completesWithEmptyArray()
        
        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let lessThanSevenDays = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetreival(with: feed.locals, timestamp: lessThanSevenDays)

        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_load_hasNoSideEffectsWhenDeleteOldCache() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let sevenDays = fixedCurrentDate.adding(days: -7)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetreival(with: feed.locals, timestamp: sevenDays)

        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_load_hasNoSideEffectsOnMoreThanSevenDaysOldCache() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let moreThanSevenDays = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetreival(with: feed.locals, timestamp: moreThanSevenDays)

        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_load_doesNotReceiveResultsWhenSUTWasDeallocated() {
        let store = FeedStoreSpy()
        var sut: CacheFeedLoader? = CacheFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [CacheFeedLoader.LoadResult]()
        
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        
        store.completesWithEmptyArray()

        XCTAssertTrue(receivedResults.isEmpty)
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
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: CacheFeedLoader) {
        let store = FeedStoreSpy()
        let sut = CacheFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (store, sut)
    }

}

