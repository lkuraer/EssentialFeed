//
//  RemoteFeedLoaderTests.swift
//  Tests iOS
//
//  Created by Ruslan Sabirov on 27.07.2022.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_reqeustsCompletesWithClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity)) {
            let clientError = NSError(domain: "test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_reqeustsCompletesWithDataError() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { (index, code) in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                let jsonData = makeDataFromJson([])
                client.complete(with: code, data: jsonData, at: index)
            }
        }
    }
    
    func test_load_reqeustsCompletesWith200responseAndInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData)) {
            client.complete(with: 200, data: Data(_: "invalid".utf8))
        }
    }
    
//    func test_load_reqeustsCompletesWith200AndEmptyJSONArray() {
//        let (sut, client) = makeSUT()
//        
//        expect(sut, toCompleteWith: .success([])) {
//            let emptyArray = makeDataFromJson([])
//            client.complete(with: 200, data: emptyArray)
//        }
//    }
//    
//    func test_load_requestsCompletesWith200AndFeedItemsArray() {
//        let (sut, client) = makeSUT()
//
//        let item1 = createItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://an-url.com")!)
//        
//        let item2 = createItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string: "https://another-url.com")!)
//
//        let items = [item1.model, item2.model]
//        
//        expect(sut, toCompleteWith: .success(items)) {
//            let data = makeDataFromJson([item1.json, item2.json])
//            client.complete(with: 200, data: data)
//        }
//    }
    
    func test_load_doNotReceiveResultWhenSUTWasDeallocated() {
        let client = HTTPClientSpy()
        let url = URL(string: "https://any-url.com")!
        
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut?.load(completion: {
            capturedErrors.append($0)
        })
        
        sut = nil
        
        let emptyArray = makeDataFromJson([])
        client.complete(with: 200, data: emptyArray)

        XCTAssertTrue(capturedErrors.isEmpty)
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
        
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }

    private func createItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": model.id.uuidString,
            "description": model.description,
            "location": model.location,
            "image": model.imageURL.absoluteString
        ].reduce(into: [String: Any]()) { partialResult, e in
            if let value = e.value {
                partialResult[e.key] = value
            }
        }
        
        return (model, json)
    }
    
    private func makeDataFromJson(_ items: [[String: Any]]) -> Data {
        let data = try! JSONSerialization.data(withJSONObject: items)
        return data
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "wait for test result")
        
        sut.load { receivedResult in
            switch (receivedResult, expectResult) {
            case let (.success(receivedItems), .success(expectItems)):
                XCTAssertEqual(receivedItems, expectItems, file: file, line: line)

            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(with statusCode: Int, data: Data, at index: Int = 0) {
            let httpResponse = HTTPURLResponse(url: requestedURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, httpResponse))
        }
    }
}
