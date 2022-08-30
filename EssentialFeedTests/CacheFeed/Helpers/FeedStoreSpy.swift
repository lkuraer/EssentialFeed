//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Ruslan Sabirov on 26.08.2022.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    
    var deletionCompletions = [DeletionCompletion]()
    var insertionCompletions = [InsertionCompletion]()
    var retreivalCompletions = [RetreivalCompletion]()
    
    var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert([LocalFeedImage], Date)
        case retreive
    }
    
    func deleteCache(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionOnSuccess(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retreive(completion: @escaping RetreivalCompletion) {
        retreivalCompletions.append(completion)
        receivedMessages.append(.retreive)
    }
    
    func completeRetreival(with error: Error, at index: Int = 0) {
        retreivalCompletions[index](error)
    }

}
