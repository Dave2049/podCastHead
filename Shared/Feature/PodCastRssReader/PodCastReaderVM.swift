//
//  PodCastReader.swift
//  PodCastHead
//
//  Created by David Schnurr on 20.02.21.
//

import Foundation
import Combine
import SwiftUI
import CoreData
import FeedKit
class PodCastReaderVM: ObservableObject{
    
    @Published private(set) var state : AppState
   
    private var bag = Set<AnyCancellable>()

    private let input = PassthroughSubject<Event, Never>()
    @Published var details = false
    @Published var podCastModel = PodCastModel()
    
    init(context: NSManagedObjectContext) {
        state = AppState.load
        
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.loadFeed(context: context),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
       
        }
    
    deinit {
        bag.removeAll()
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<AppState, Event> {
        Feedback { _ in input }
    }

    func selectEpisode(model: PodcastReaderModel, episode: PodPlayerModel){
    
        
        
        send(event: .onSelectEpisode(model))
    }
    
    func addPodCast(model: PodcastReaderModel){
        var tmpModel = model
        tmpModel.newPodCast = podCastModel
        send(event: .onAddPodcast(tmpModel))
        
    }
    
    func send(event: Event) {
        input.send(event)
    }
}
extension PodCastReaderVM{
    enum AppState {
        case idle(PodcastReaderModel)
        case load
        case error(Error)
        case savingPodCast(PodcastReaderModel)
    }
    
    enum Event {
        case onError(Error)
        case onLoad(PodcastReaderModel)
        case loaded(PodcastReaderModel)
        case onSelectEpisode(PodcastReaderModel)
        case onAddPodcast(PodcastReaderModel)
        case onSavedPodCast(PodcastReaderModel)
    }
    
    static func reduce(_ state: AppState, _ event: Event) -> AppState {
        switch state {
        case .load:
            switch event {
            case .loaded(let model):
                return .idle(model)
            default:
                return state
            }
        case .savingPodCast:
            switch event {
            case .onSavedPodCast(let model):
                return .idle(model)
            default:
                return state
            }
        
        case .idle:
            switch event {
            case .onSelectEpisode(let model):
                return .idle(model)
           
            case .onAddPodcast(let model):
                return .savingPodCast(model)
            default:
                return state
            }
        default:
            return state
        
    }
    }
    
    // TODO: handle loaded podcast and add into the list
    
    static func savePodcast(context: NSManagedObjectContext) -> Feedback<AppState, Event> {
     Feedback { (state: AppState) -> AnyPublisher<Event, Never> in
        guard case .savingPodCast(let model) = state else { return Empty().eraseToAnyPublisher() }
        return propagateCategory(context: context, model: model)
            .map({Event.onSavedPodCast($0)})
            .catch { Just(Event.onError($0)) }
            .eraseToAnyPublisher()
        
     }
        
    }
    
    static func propagateCategory(context: NSManagedObjectContext, model: PodcastReaderModel) -> AnyPublisher<PodcastReaderModel, Error>{
        return Future{ promise in
        let podcast = PodCast(context: context)
            do{
            guard let newPodcast = model.newPodCast else{
                throw RssExceptions.noEpisodes
            }
            podcast.name = newPodcast.podCastName
            podcast.rssFeed = newPodcast.podCastName
            
            var tmpModel = model
           
            guard let url = URL(string: newPodcast.podCastName) else {
               throw RssExceptions.noRssFormat
            }
            let podCastContent = try parseFeed(feed: url)
                
            tmpModel.podCastModel.append(podCastContent)
            try context.save()
            promise(.success(tmpModel))
            } catch let error {
                promise(.failure(error))
            }
           
            
        }.eraseToAnyPublisher()
    }
    
    static func loadFeed(context: NSManagedObjectContext) -> Feedback<AppState, Event> {
     Feedback { (state: AppState) -> AnyPublisher<Event, Never> in
         guard case .load = state else { return Empty().eraseToAnyPublisher() }
     
        return fetchPodcasts(context: context)
             .map({Event.loaded($0)})
             .catch { Just(Event.onError($0)) }
             .eraseToAnyPublisher()

     }
    }
     
    
    static func fetchPodcasts(context: NSManagedObjectContext) -> AnyPublisher<PodcastReaderModel, Error>{
        return Future { promise in
         do {
        let podCastsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Podcast")
            let podcasts = try context.fetch(podCastsFetch) as! [PodCast]
            
            let podCastsModel = try podcasts.filter({$0.rssFeed != nil})
                .map({$0.rssFeed!})
                .map({try parseFeed(feed: URL(string: $0)!)})
            
            promise(.success(PodcastReaderModel(podCastModel: podCastsModel)))
         }catch let error{
            promise(.failure(error))
        }
        }.eraseToAnyPublisher()
    }
    
    
    
     static func parseFeed(feed: URL) throws -> RssReader {
       
         do {
             let rssFeed = try RssConverter.loadRssFeed(feed: feed)
             return try parseRSSfeed(rssFeed: rssFeed, orgFeed: feed)
             
         } catch let error {
             throw error
         }
        
     }
     
     static func parseRSSfeed(rssFeed: RSSFeed, orgFeed: URL) throws -> RssReader{
        
         
             // Grab the parsed feed directly as an optional rss, atom or json feed object
        guard let title = rssFeed.title else{
            throw RssExceptions.noTitle
        }
        
        
        let podcast = PodCastModel(podCastName: title, rssFeed: orgFeed.absoluteString, description: rssFeed.description, imageUrl: getImageURL(image: rssFeed.image?.url, feedImage: nil))
            
             
             guard let items = rssFeed.items else {
                 throw RssExceptions.noEpisodes
             }
             
        
        
             let episodes : [PodPlayerModel] = items.compactMap{
                 debugPrint( ($0.iTunes?.iTunesDuration ?? 1) / 60)
                return PodPlayerModel(imageUrl: getImageURL(image: $0.iTunes?.iTunesImage?.attributes?.href, feedImage: rssFeed.image?.url), mp3Url: URL(string: $0.enclosure?.attributes?.url ?? "google.de")!, text: $0.title! , pub: $0.pubDate, player: RssReaderViewModel.avPlayer,description: $0.description ?? "", duration: $0.iTunes?.iTunesDuration )
           
             }
        return RssReader(podcast: podcast, feed: orgFeed, name: title, episodes: episodes, selectedEpisode: nil)
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

}

