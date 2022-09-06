//
//  ValidateCacheBeforeRetreivalTestCase.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 06.09.2022.
//

import Foundation
import EssentialFeed
import XCTest

class ValidateCacheBeforeRetreivalTestCase: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (store, _) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validate_deletesCacheOnRetreivalError() {
        let (store, sut) = makeSUT()
        
        sut.validateCache()
        store.completeRetreival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retreive, .deleteCacheFeed])
    }
    
    func test_validate_doesNotDeleteCacheWhenCacheIsEmpty() {
        let (store, sut) = makeSUT()
        
        sut.validateCache()
        store.completesWithEmptyArray()
        
        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_validate_doesNotDeleteCacheWhenSevenDaysOldCache() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let lessThanSevenDays = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetreival(with: feed.locals, timestamp: lessThanSevenDays)

        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    func test_validate_deleteOldCache() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let sevenDays = fixedCurrentDate.adding(days: -7)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetreival(with: feed.locals, timestamp: sevenDays)

        XCTAssertEqual(store.receivedMessages, [.retreive, .deleteCacheFeed])
    }
    
    func test_validate_moreThanSevenDaysOldCache() {
        let feed = uniqueItems()
        let fixedCurrentDate = Date()
        let moreThanSevenDays = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetreival(with: feed.locals, timestamp: moreThanSevenDays)

        XCTAssertEqual(store.receivedMessages, [.retreive, .deleteCacheFeed])
    }

    func test_validation_deallocatingWhenSUTWasDeallocated() {
        let store = FeedStoreSpy()
        var sut: CacheFeedLoader? = CacheFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        sut = nil
        
        store.completeRetreival(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retreive])
    }

    // Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: CacheFeedLoader) {
        let store = FeedStoreSpy()
        let sut = CacheFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (store, sut)
    }

}
