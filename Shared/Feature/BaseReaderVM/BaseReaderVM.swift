//
//  BaseReaderVM.swift
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

class BaseReaderVM : ObservableObject{
    
    @Published public var state : AppState
   
    private var bag = Set<AnyCancellable>()

    private let input = PassthroughSubject<Event, Never>()
    @Published var details = false
    
    init(model: BaseRssReader) {
        state = AppState.load(model)
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
            //    Self.loadFeed(),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
            
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)

        }
    
    deinit {
        bag.removeAll()
    }
    
   func loadFeed() -> Feedback<AppState, Event> {
    Feedback { (state: AppState) -> AnyPublisher<Event, Never> in
        guard case .load(let model) = state else { return Empty().eraseToAnyPublisher() }
    
        return self.parseFeed(feed: model.feedURL)
            .map({Event.loaded($0)})
            .catch { Just(Event.onError($0)) }
            .eraseToAnyPublisher()

    }
   }
    
    func parseFeed(feed: URL) -> AnyPublisher<BaseRssReader, Error> {
       return Future { promise in
        do {
            let rssFeed = try RssConverter.loadRssFeed(feed: feed)
            let reader = try self.parseRSSfeed(rssFeed: rssFeed, orgFeed: feed)
            promise(.success(reader))
        } catch let error {
            promise(.failure(error))
        }
       
            
        }.eraseToAnyPublisher()
    }
    
    func send(event: Event) {
        input.send(event)
    }
}

extension BaseReaderVM{
    enum AppState {
        case idle(BaseRssReader)
        case load(BaseRssReader)
        case error(Error)
    }
    
    enum Event {
        case onError(Error)
        case onLoad(BaseRssReader)
        case loaded(BaseRssReader)
        case onSelect(BaseRssReader)
    }
}
extension BaseReaderVM{
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
            case .onSelect(let model):
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
   
    
    func parseRSSfeed(rssFeed: RSSFeed, orgFeed: URL) throws -> BaseRssReader{
       
        guard let title = rssFeed.title else {
            debugPrint("no Title in RssFeed")
            throw RssExceptions.noRssFormat
        }
        return BaseRssReader(feed: orgFeed, name: title, rssFeed: rssFeed)
    }
    
}

