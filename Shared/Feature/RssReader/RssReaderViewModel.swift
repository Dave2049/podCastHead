//
//  RssReaderViewModel.swift
//  PodCastHead
//
//  Created by David Schnurr on 24.01.21.
//

import Foundation
import Combine
import FeedKit
import AVKit
import MediaPlayer
import SwiftUI
class RssReaderViewModel: ObservableObject{
    
    @Published private(set) var state : AppState
   
    private var bag = Set<AnyCancellable>()

    private let input = PassthroughSubject<Event, Never>()
    @Published var details = false
    private static let avPlayer = AVPlayer()
    
    
    init(model: RssReader) {
        state = AppState.load(model)
        #if os(iOS)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        #endif
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.loadFeed(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
        #if os(iOS)
        setUpAvSession()
        setupRemoteTransportControls()
        #endif
        }
    
    deinit {
        bag.removeAll()
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
   
    func selectEpisode(model: RssReader, episode: PodPlayerModel){
    
        
        if let currentEpisode = model.selectedEpisode{
            currentEpisode.audioPlayer.pause()
        }
        var tmpModel = model
        let playerItem = AVPlayerItem(url: episode.mp3Url)
        RssReaderViewModel.avPlayer.replaceCurrentItem(with: playerItem)
        tmpModel.selectedEpisode = episode
        details = true
        send(event: .onSelectEpisode(tmpModel))
    }
    
    func send(event: Event) {
        input.send(event)
    }
}

extension RssReaderViewModel{
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
}
extension RssReaderViewModel{
    static func reduce(_ state: AppState, _ event: Event) -> AppState {
        switch state {
        case .load:
            switch event {
            case .loaded(let model):
                return .idle(model)
            default:
                return state
            }
            
        case .idle:
            switch event {
            case .onSelectEpisode(let model):
                return .idle(model)
            default:
                return state
            }
        default:
            return state
        
    }
    }
    
  
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<AppState, Event> {
        Feedback { _ in input }
    }
    
   static func loadFeed() -> Feedback<AppState, Event> {
    Feedback { (state: AppState) -> AnyPublisher<Event, Never> in
        guard case .load(let model) = state else { return Empty().eraseToAnyPublisher() }
    
        return parseFeed(feed: model.feed)
            .map({Event.loaded($0)})
            .catch { Just(Event.onError($0)) }
            .eraseToAnyPublisher()

    }
   }
    
    static func parseFeed(feed: URL) -> AnyPublisher<RssReader, Error> {
       return Future { promise in
        debugPrint(feed)
        let parser = FeedParser(URL: feed)
        let result = parser.parse()
        do {
        let reader = try parseRSSfeed(result: result, orgFeed: feed)
            promise(.success(reader))
        } catch let error {
            promise(.failure(error))
        }
       
            
        }.eraseToAnyPublisher()
    }
    
    static func parseRSSfeed(result: Result<Feed, ParserError>, orgFeed: URL) throws -> RssReader{
        switch result {
        case .success(let feed):
        
            // Grab the parsed feed directly as an optional rss, atom or json feed object
            guard let content = feed.rssFeed else{
                throw RssExceptions.noRssFormat
            }
            
            guard let items = content.items else {
                throw RssExceptions.noEpisodes
            }
            
            let episodes : [PodPlayerModel] = items.compactMap{
                debugPrint( ($0.iTunes?.iTunesDuration ?? 1) / 60)
                return PodPlayerModel(imageUrl: getImageURL(image: $0.iTunes?.iTunesImage?.attributes?.href, feedImage: content.image?.url), mp3Url: URL(string: $0.enclosure?.attributes?.url ?? "google.de")!, text: $0.title! , pub: $0.pubDate, player: avPlayer,description: $0.description ?? "", duration: $0.iTunes?.iTunesDuration )
               
          //      return PodPlayerModel(imageUrl: URL(string:$0.iTunes?.iTunesImage?.attributes?.href ?? "google.de"), mp3Url: URL(string: "https://hwcdn.libsyn.com/p/c/0/e/c0e1b0b925bd42b4/Kapitel_Eins_Folge_63.mp3?c_id=94444499&cs_id=94444499&expiration=1612034584&hwt=b50b1e7e037ae9f91fe84a7b8bf86313")!, text: $0.title! , pub: $0.pubDate)
            }
            return RssReader(feed: orgFeed, name: content.title!, episodes: episodes, selectedEpisode: nil)
            
        case .failure(let error):
            
            print(error)
            throw RssExceptions.noRssFormat
        }
    }
    

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

enum RssExceptions: Error{
    case noRssFormat
    case noTitle
    case noEpisodes
}


extension RssReaderViewModel{
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if RssReaderViewModel.avPlayer.rate == 0.0 {
                RssReaderViewModel.avPlayer.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if RssReaderViewModel.avPlayer.rate == 1.0 {
                RssReaderViewModel.avPlayer.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
}
