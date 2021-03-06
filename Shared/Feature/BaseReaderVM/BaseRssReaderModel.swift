//
//  BaseRssReaderModel.swift
//  PodCastHead
//
//  Created by David Schnurr on 20.02.21.
//

import Foundation
import FeedKit
class BaseRssReader{
    init(feed: URL, name: String, rssFeed: RSSFeed? = nil) {
        self.feedURL = feed
        self.name = name
        self.rssFeed = rssFeed
    }
    
    var rssFeed: RSSFeed?
    var feedURL: URL
    var name: String
}
