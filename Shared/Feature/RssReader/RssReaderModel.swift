//
//  RssReaderModel.swift
//  PodCastHead 
//
//  Created by David Schnurr on 24.01.21.
//

import Foundation

struct RssReader{
    
    var feed: URL
    var name: String
    var episodes: [PodPlayerModel]?
    var selectedEpisode: PodPlayerModel?
}
