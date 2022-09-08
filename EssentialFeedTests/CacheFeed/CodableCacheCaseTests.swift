//
//  CodableCacheCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 07.09.2022.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    func retreive(completion: @escaping FeedStore.RetreivalCompletion) {
        completion(.empty)
    }

}

class CodableCacheCaseTests: XCTestCase {

    func test_retreive_hasNoSideEffectsWhenDeliverEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for cache retreival")
        
        sut.retreive { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("We expected empty result, but received: \(result)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retreive_hasNoSideEffectsWhenDeliverEmptyOnEmptyCacheTwice() {
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for cache retreival")
        
        sut.retreive { firstResult in
            sut.retreive { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("We expected empty result, but received: \(firstResult) and \(secondResult)")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }

    
}
