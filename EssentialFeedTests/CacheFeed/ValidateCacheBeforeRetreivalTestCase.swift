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
    
    func test_validate_hasNoSideEffectsWhenCacheIsEmpty() {
        let (store, sut) = makeSUT()
        
        sut.validateCache()
        store.completesWithEmptyArray()
        
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
