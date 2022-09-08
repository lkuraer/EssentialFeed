//
//  CodableCacheCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 07.09.2022.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let imageURL: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            imageURL = image.imageURL
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, imageURL: imageURL)
        }

    }

    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("essentialfeed.store")
    
    func retreive(completion: @escaping FeedStore.RetreivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let jsonDecoder = JSONDecoder()
        let decoded = try! jsonDecoder.decode(Cache.self, from: data)
        completion(.found(feed: decoded.localFeed, timestamp: decoded.timestamp))
    }

    func insert(items: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let jsonEncoder = JSONEncoder()
        let cache = Cache(feed: items.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! jsonEncoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableCacheCaseTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        
        cleanData()
    }

    override class func tearDown() {
        super.tearDown()
        
        cleanData()
    }
    
    func test_retreive_hasNoSideEffectsWhenDeliverEmptyOnEmptyCache() {
        cleanData()

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
        cleanData()

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

    func test_insertSampleDataAndThenRetreiveData() {
        let sut = CodableFeedStore()
        let feed = uniqueItems().locals
        let timestamp = Date()

        let exp = expectation(description: "Wait for cache retreival")

        sut.insert(items: feed, timestamp: timestamp) { insertError in
            XCTAssertNil(insertError, "We expect that insertion was successfull")

            sut.retreive { retreivedResult in
                switch retreivedResult {
                case .found(let receivedFeed, let receivedTimestamp):
                    XCTAssertEqual(receivedFeed, feed)
                    XCTAssertEqual(receivedTimestamp, timestamp)

                default:
                    XCTFail("We expected to receive feed \(feed) and timestamp: \(timestamp), but received \(retreivedResult)")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }


    
}
