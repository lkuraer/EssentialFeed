//
//  TestsHelpers.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 06.09.2022.
//

import Foundation
import EssentialFeed


func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func uniqueItem() -> FeedImage {
    return FeedImage(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://any-url.com")!)
}

func uniqueItems() -> (models: [FeedImage], locals: [LocalFeedImage]) {
    let items = [uniqueItem(), uniqueItem()]
    let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
    return (items, localItems)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyData() -> Data {
    return Data(_: "any data".utf8)
}

