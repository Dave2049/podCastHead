//
//  RssConverter.swift
//  PodCastHead
//
//  Created by David Schnurr on 20.02.21.
//

import Foundation
import Combine
import FeedKit
import SwiftUI

struct RssConverter{
    
    
    public static func loadRssFeed(feed: URL) throws -> RSSFeed{
        let parser = FeedParser(URL: feed)
        let result = parser.parse()
        switch result {
        case .failure(let error):
            print(error)
            throw RssExceptions.noRssFormat
        case .success(let feed):
            guard let rssFeed = feed.rssFeed else {
                throw RssExceptions.noRssFormat
            }
            return rssFeed
        }
        
    }
    
    
     
}

enum RssExceptions: Error{
    case noRssFormat
    case noTitle
    case noEpisodes
}
