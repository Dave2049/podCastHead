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
    static let avPlayer = AVPlayer()
    
    
    init(model: RssReader) {
        state = AppState.idle(model)
        #if os(iOS)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        #endif
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
               // Self.loadFeed(),
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
