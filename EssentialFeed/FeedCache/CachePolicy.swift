//
//  CachePolicy.swift
//  EssentialFeed
//
//  Created by Ruslan Sabirov on 07.09.2022.
//

import Foundation

internal final class CachePolicy {
    init() {}
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxDays: Int {
        return 7
    }
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxAge = calendar.date(byAdding: .day, value: maxDays, to: timestamp) else {
            return false
        }
        
        return date < maxAge
    }
}

