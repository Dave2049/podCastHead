//
//  RssReaderModel.swift
//  PodCastHead 
//
//  Created by David Schnurr on 24.01.21.
//

import Foundation

struct RssReader : Hashable{
    var podcast: PodCastModel
    var feed: URL
    var name: String
    var episodes: [PodPlayerModel]?
    var selectedEpisode: PodPlayerModel?
}

class RssReaderEpisodeModel: BaseRssReader{
    init(base: BaseRssReader,episodes: [PodPlayerModel]? = nil, selectedEpisode: PodPlayerModel? = nil) {
        super.init(feed: base.feedURL, name: base.name)
        self.episodes = episodes
        self.selectedEpisode = selectedEpisode
    }
    
    var episodes: [PodPlayerModel]?
    var selectedEpisode: PodPlayerModel?
}
