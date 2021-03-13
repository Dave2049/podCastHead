//
//  RssReaderView.swift
//  PodCastHead 
//
//  Created by David Schnurr on 24.01.21.
//

import SwiftUI

struct RssReaderView: View {
    @ObservedObject var viewModel : RssReaderViewModel
 //   @EnvironmentObject var reader: EnvReader
    @State var expandDescription = false
    var body: some View {
        content()
    }
        func content() -> some View {
            switch viewModel.state {
                case .load:
                    return loadingView().eraseToAnyView()
            case .idle(let model):
                    return idleView(model: model).eraseToAnyView()
            case .error(let error):
               return Text(error.localizedDescription).eraseToAnyView()
            }
        }
    
    func idleView(model: RssReader) -> some View {
      
        VStack{
           
            #if os(iOS)
            
            if let selectedEpisode = model.selectedEpisode{
                EmptyView()
                .sheet(isPresented: $viewModel.details){
                    PodPlayerView(viewModel: PodPlayerViewModel(model: selectedEpisode))
                }
            }
        #else
            Text(model.name).font(.title)
            if let selectedEpisode = model.selectedEpisode{
              
            NavigationLink(destination:   PodPlayerView(viewModel: PodPlayerViewModel(model: selectedEpisode)) /*.environmentObject(reader)*/, isActive: $viewModel.details){
                EmptyView()
            }
            }
        #endif
                List(model.episodes!){ episode in
                  
                    HStack{
                        Text(episode.title)
                        Spacer()
                        Button("Play", action: {viewModel.selectEpisode(model: model, episode: episode)})
                    }
                    
                }
        
        }.navigationBarTitle(model.name)
    }
    
    func loadingView() -> some View{
        ProgressView("Loading")
    }
    
}


class EnvReader : ObservableObject{
    internal init(size: CGSize? = nil) {
        self.size = size
    }
    
    var size : CGSize?
}
