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
        sut.load { result in
            switch result {
            case .failure(let error):
                receivedError = error
            default:
                XCTFail("Failed to pass test, completion returns result success: \(result)")
            }
            exp.fulfill()
        }
        
        store.completeRetreival(with: expectedError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(expectedError, receivedError as? NSError)
    }

    func test_load_requestCacheCompletesWithEmptyArray() {
        let (store, sut) = makeSUT()
        
        let exp = expectation(description: "Wait for result")
    
        var receivedImages: [FeedImage]?
        sut.load { result in
            switch result {
            case .success(let images):
                receivedImages = images
            default:
                XCTFail("Failed to pass test, completion returns result failure: \(result)")
            }
            exp.fulfill()
        }
        
        store.completesWithEmptyArray()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedImages, [])
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
