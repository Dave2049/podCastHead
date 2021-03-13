//
//  PodCastRssReaderView.swift
//  PodCastHead
//
//  Created by David Schnurr on 04.03.21.
//

import SwiftUI
import URLImage

struct PodCastRssReaderView: View {
    
    @State var addPodCast = false
    
    @ObservedObject var viewModel : PodCastReaderVM
    
    var body: some View {
        content()
    }
        func content() -> some View {
            switch viewModel.state {
            case .load, .savingPodCast:
                    return loadingView().eraseToAnyView()
            case .idle(let model):
                    return idleView(model: model).eraseToAnyView()
            case .error(let error):
               return Text(error.localizedDescription).eraseToAnyView()
            
        }
        }
    
    func loadingView() -> some View{
        ProgressView("Loading")
    }
    
    
    
    fileprivate func podCastItem(podCast: RssReader, size: CGSize, name: String)  -> some View{
        VStack{
            if let image = podCast.podcast.imageUrl{
                URLImage(url: image) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 10)
                }.frame(maxWidth: size.width * 0.8, maxHeight: size.height * 0.3)
            }
            Text(name)
            Divider()
        }.padding()
    }
    
    func idleView(model: PodcastReaderModel) -> some View {
        GeometryReader{ reader in
            
        
        VStack{
            if addPodCast{
            HStack{
                TextField("name", text: $viewModel.podCastModel.podCastName).padding()
                TextField("RssFeed", text: $viewModel.podCastModel.rssFeed).padding()
            }
            Button("Save"){
                viewModel.addPodCast(model: model)
            }
            
            }
            Divider()
            ForEach(model.podCastModel, id: \.self) { podCast in
            if let name = podCast.name{
                NavigationLink(
                    destination: RssReaderView(viewModel: RssReaderViewModel(model: podCast))){
                    podCastItem(podCast: podCast, size: reader.size, name: name)
                }
            }
           
            }
        
        
        }.navigationBarItems(trailing:
            Button{
                addPodCast.toggle()
            }label:{
                    Label(addPodCast ? "Add Podcast" : "close", systemImage: addPodCast ? "plus.app" : "minus.square")
            }.padding(.horizontal)
        ).navigationBarTitle("PodCastHead")
        }
    }
}

