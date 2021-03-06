//
//  RssEpisodeViewModel.swift
//  PodCastHead
//
//  Created by David Schnurr on 20.02.21.
//

import Foundation

import Foundation
import Combine
import FeedKit
import AVKit
import MediaPlayer
import SwiftUI
class RssEpisodeViewModel: BaseReaderVM{
    

    private static let avPlayer = AVPlayer()
    
    
    init(model: RssReaderEpisodeModel) {
        super.init(model: model)
        #if os(iOS)
        setUpAvSession()
        setupRemoteTransportControls()
        #endif
        }
    
    #if os(iOS)
    func setUpAvSession(){
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
    }
    #endif
   
    func selectEpisode(model: RssReaderEpisodeModel, episode: PodPlayerModel){

        if let currentEpisode = model.selectedEpisode{
            currentEpisode.audioPlayer.pause()
        }
        var tmpModel = model
        let playerItem = AVPlayerItem(url: episode.mp3Url)
        RssEpisodeViewModel.avPlayer.replaceCurrentItem(with: playerItem)
        tmpModel.selectedEpisode = episode
        details = true
        send(event: .onSelect(tmpModel))
    }
    override func loadFeed() -> Feedback<AppState, Event> {
      Feedback { (state: AppState) -> AnyPublisher<Event, Never> in
          guard case .load(let model) = state else { return Empty().eraseToAnyPublisher() }
      
        return self.parseFeed(feed: model.feedURL)
              .flatMap({self.convertEpisode(baseModel: $0)})
              .map({Event.loaded($0)})
              .catch { Just(Event.onError($0)) }
              .eraseToAnyPublisher()

      }
     }
    
    func convertEpisode(baseModel: BaseRssReader) -> AnyPublisher<RssReaderEpisodeModel, Error> {
       return Future { promise in
        do {
            let rssFeed = try RssConverter.loadRssFeed(feed: baseModel.feedURL)
            let reader = try self.parseRSSEpisode(rssFeed: rssFeed, base: baseModel)
            promise(.success(reader))
        } catch let error {
            promise(.failure(error))
        }
       
            
        }.eraseToAnyPublisher()
    }
    
    func parseRSSEpisode(rssFeed: RSSFeed, base: BaseRssReader) throws -> RssReaderEpisodeModel{
       
        
            // Grab the parsed feed directly as an optional rss, atom or json feed object
            
            
            guard let items = rssFeed.items else {
                throw RssExceptions.noEpisodes
            }
            
            let episodes : [PodPlayerModel] = items.compactMap{
                debugPrint( ($0.iTunes?.iTunesDuration ?? 1) / 60)
                return PodPlayerModel(imageUrl: RssEpisodeViewModel.getImageURL(image: $0.iTunes?.iTunesImage?.attributes?.href, feedImage: rssFeed.image?.url), mp3Url: URL(string: $0.enclosure?.attributes?.url ?? "google.de")!, text: $0.title! , pub: $0.pubDate, player: RssEpisodeViewModel.avPlayer,description: $0.description ?? "", duration: $0.iTunes?.iTunesDuration )
          
            }
        return RssReaderEpisodeModel(base: base, episodes: episodes, selectedEpisode: nil)
        
    }
    
}
/*
extension RssEpisodeViewModel{
    enum AppState {
        case idle(RssReader)
        case load(RssReader)
        case error(Error)
    }
    
    enum Event {
        case onError(Error)
        case onLoad(RssReader)
        case loaded(RssReader)
        case onSelectEpisode(RssReader)
    }
} */
extension RssEpisodeViewModel{
    

    
    
    

    static func getImageURL(image: String?, feedImage: String?) -> URL?{
        if let image = image{
            return URL(string: image)
        }else if let image = feedImage{
            return URL(string: image)
        } else {
            return nil
        }
    }
    
        //https://hwcdn.libsyn.com/p/c/0/e/c0e1b0b925bd42b4/Kapitel_Eins_Folge_63.mp3?c_id=94444499&cs_id=94444499&expiration=1612034584&hwt=b50b1e7e037ae9f91fe84a7b8bf86313
    
}


extension RssEpisodeViewModel{
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if RssEpisodeViewModel.avPlayer.rate == 0.0 {
                RssEpisodeViewModel.avPlayer.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if RssEpisodeViewModel.avPlayer.rate == 1.0 {
                RssEpisodeViewModel.avPlayer.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
}
