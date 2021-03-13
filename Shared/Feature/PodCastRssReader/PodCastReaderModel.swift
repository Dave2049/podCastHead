//
//  PodCastReaderModel.swift
//  PodCastHead
//
//  Created by David Schnurr on 04.03.21.
//

import Foundation

struct PodCastModel : Hashable{
    var podCastName = ""
    var rssFeed = ""
    var description : String?
    var imageUrl : URL?
}

struct PodcastReaderModel {
    var podCastModel : [RssReader]
    var newPodCast: PodCastModel?
}

enum PodCastReaderError: Error{
    case dublicatedRSS
}
