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
        
        let exp = expectation(description: "Wait for error response")
    
        var receivedError: Error?
        sut.load { error in
            receivedError = error as? NSError
            exp.fulfill()
        }
        
        store.completeRetreival(with: expectedError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(expectedError, receivedError as? NSError)
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

}
