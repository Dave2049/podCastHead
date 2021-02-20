//
//  PodPlayerViewModel.swift
//  PodCastHead
//
//  Created by David Schnurr on 24.01.21.
//

import Foundation
import Combine
import AVKit
class PodPlayerViewModel: ObservableObject{
    @Published private(set) var state : AppState
    
    private var bag = Set<AnyCancellable>()
    var seekTime = Double(2)
    @Published var playerTime = ""
    let publishers = PassthroughSubject<TimeInterval, Never>()
    private let input = PassthroughSubject<Event, Never>()
    private var timeObservation: Any?
    
    
    
    init(model: PodPlayerModel) {
        model.audioPlayer.status
        state = AppState.stop(model)
        initalizeObserver(player: model.audioPlayer)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.loadPlayerItem(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
        play(model: model)
    }
    
    deinit {
        bag.removeAll()
    }
    
    func secondsToCMTIME(seconds: Double) -> CMTime{
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }
    
    func initalizeObserver(player: AVPlayer){
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { [weak self] time in
              // Publish the new player time
            guard let self = self else { return }
            
            self.playerTime = "\(time.positionalTime)"
           
            self.seekTime = Double(time.minute)
        }
        
        
    }
    
    func seekTime(player: AVPlayer){
        let targetTime = self.seekTime //* player.currentItem!.duration.seconds
        
        player.seek(to: CMTime(seconds: targetTime * 60, preferredTimescale: 600))
    }
    
    func play(model: PodPlayerModel){
        model.audioPlayer.play()
        send(event: .onLoad(model))
    }
    func stop(model: PodPlayerModel){
        model.audioPlayer.pause()
        send(event: .onStop(model))
    }
    func send(event: Event) {
        input.send(event)
    }
}

extension PodPlayerViewModel{
    enum AppState {
        case buffering(PodPlayerModel)
        case play(PodPlayerModel)
        case stop(PodPlayerModel)
        case error(Error)
    }
    
    enum Event {
        case onLoad(PodPlayerModel)
        case onPlay(PodPlayerModel)
        case onStop(PodPlayerModel)
        case onError(Error)
    }
}
extension PodPlayerViewModel{
    static func reduce(_ state: AppState, _ event: Event) -> AppState {
        switch state {
        case .play:
            switch event {
            case .onStop(let model):
                return .stop(model)
            default:
                return state
            }
            
        case .stop:
            switch event {
            case .onLoad(let model):
                return .buffering(model)
            case .onPlay(let model):
                return .play(model)
            default:
                return state
            }
        case .buffering:
            switch event {
            case .onPlay(let model):
                return .play(model)
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
    static func loadPlayerItem() -> Feedback<AppState, Event> {
     Feedback { (state: AppState) -> AnyPublisher<Event, Never> in
        guard case .buffering(let model) = state else { return Empty().eraseToAnyPublisher() }
        return waitAndInitialize(player: model.audioPlayer)
             .map({Event.onPlay(model)})
             .catch { Just(handleAVerror(error: $0, model: model)) }
             .eraseToAnyPublisher()
     }
    }
    
    static func handleAVerror(error: Error, model: PodPlayerModel) -> Event{

        switch error {
        case AVError.episodeNotReady:
            return .onLoad(model)
        default:
            return .onError(error)
        }
    }
   
    static func waitAndInitialize(player: AVPlayer) -> AnyPublisher<Void,Error> {
        Future { promise in
            if(player.ready){
                promise(.success(Void()))
            }else{
                promise(.failure(AVError.episodeNotReady))
            }
        }.eraseToAnyPublisher()
    }
    
    
}

extension AVPlayer {
    var ready:Bool {
        let timeRange = currentItem?.loadedTimeRanges.first as? CMTimeRange
       
        guard let duration = timeRange?.duration else { return false }
        
        let timeLoaded = Int(duration.value) / Int(duration.timescale) // value/timescale = seconds
        debugPrint(currentItem?.duration.minute)
        let loaded = timeLoaded > 0
        return status == .readyToPlay && loaded
    }
}

enum AVError : Error{
    case failureLoadingEpisode
    case episodeNotReady
}
extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    
    var hours:  Int {
        if roundedSeconds > 0{
            return Int(roundedSeconds / 3600)
        } else{
            return 0
        }
    }
    var minute: Int {
        if roundedSeconds > 0{
            return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        } else{
            return 0
        }
    }
    var second: Int {
        if roundedSeconds > 0{
            return Int(roundedSeconds.truncatingRemainder(dividingBy: 60))
        } else{
            return 0
        }
    }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
    
}
