//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Ruslan Sabirov on 27.07.2022.
//

import Foundation

public struct FeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
}
