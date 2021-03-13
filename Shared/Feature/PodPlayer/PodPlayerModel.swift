//
//  PodPlayerModel.swift
//  PodCastHead
//
//  Created by David Schnurr on 24.01.21.
//

import Foundation
import AVKit

struct PodPlayerModel: Identifiable, Hashable{
    
    var id: UUID
    
    internal init(imageUrl: URL?, mp3Url: URL, text: String, pub: Date?, player: AVPlayer, details : Bool = false, description: String, duration: Double?, guid: String, rssFeed: String?) {
        self.id = UUID()
        self.imageUrl = imageUrl
        self.mp3Url = mp3Url
        audioPlayer = player
        self.title = text
        self.published = pub
        self.details = details
        self.description = description
        self.duration = duration
        self.guid = guid
        self.rssFeed = rssFeed
    }
    var rssFeed: String?
    var podCast: PodCast?
    var details: Bool
    var title: String
    var imageUrl : URL?
    var mp3Url : URL
    var audioPlayer: AVPlayer!
    var published: Date?
    var description: String
    var duration: Double?
    var guid: String
    var fetchDuration : Double{
        if let duration = duration{
            return duration
        } else{
            return audioPlayer.currentItem?.duration.seconds ?? 0
        }
    }
    
}
