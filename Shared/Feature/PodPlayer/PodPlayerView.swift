//
//  PodPlayer.swift
//  PodCastHead
//
//  Created by David Schnurr on 24.01.21.
//

import SwiftUI
import URLImage

struct PodPlayerView: View {
    @ObservedObject var viewModel : PodPlayerViewModel
  //  @EnvironmentObject var proxy: EnvReader
    
    
    var body: some View {
       
        switch viewModel.state {
            case .play(let model), .stop(let model), .buffering(let model):
                return contentMaximised(model:model).frame(maxWidth: .infinity, maxHeight: .infinity).eraseToAnyView()
            case .error:
                return Text("failed to Load episode").frame(maxWidth: .infinity, maxHeight: .infinity).eraseToAnyView()
        }
        
    }
    
        func content() -> some View {
           
            switch viewModel.state {
                case .play(let model):
                    return playView(model: model).eraseToAnyView()
                case .stop(let model):
                    return stopView(model: model).eraseToAnyView()
                case .buffering(let model):
                    return bufferingView(title: model.title).eraseToAnyView()
                case .error:
                    return Text("failed to Load episode").eraseToAnyView()
            }
            
        }
    
    
    
    func contentMaximised(model: PodPlayerModel) -> some View{
        
        VStack{
            Text(model.title).font(.title2).padding()
            Text(model.description).lineLimit(2)
            if let image = model.imageUrl{
                URLImage(url: image) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
         //   Text(viewModel.playerTime)
            if let item = model.audioPlayer.currentItem{
                if (item.duration.minute > 0){
                    Slider(value: $viewModel.seekTime, in: 0...model.fetchDuration / 60, step: 1, onEditingChanged: { _ in
                        viewModel.seekTime(player: model.audioPlayer)
                       
                    }, minimumValueLabel: Text("\(viewModel.playerTime)"),
                    maximumValueLabel: Text("\(viewModel.secondsToCMTIME(seconds: model.fetchDuration).positionalTime)")
                ) {
                    EmptyView()
                    }.padding()
                
                }
            }
            dynButton(model: model).padding()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
        
    }
    
    func dynButton(model: PodPlayerModel)-> some View{
        switch viewModel.state {
            case .play(let model):
                return playView(model: model).eraseToAnyView()
            case .stop(let model):
                return stopView(model: model).eraseToAnyView()
             case .buffering(let model):
                return bufferingView(title: model.title).eraseToAnyView()
            default:
                return EmptyView().eraseToAnyView()
        }
    }
        
    func playView(model: PodPlayerModel) -> some View {
            VStack{
                Button("Stop"){
                    viewModel.stop(model: model)
                }
        }
    }
    
    func stopView(model: PodPlayerModel) -> some View {
            VStack{
                Button("Start"){
                    viewModel.play(model: model)
                }
        }
    }
    
    func bufferingView(title: String) -> some View {
        VStack{
            ProgressView("Loading")
        }
    }
    
}


