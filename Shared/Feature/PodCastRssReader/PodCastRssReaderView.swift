//
//  PodCastRssReaderView.swift
//  PodCastHead
//
//  Created by David Schnurr on 04.03.21.
//

import SwiftUI

struct PodCastRssReaderView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodCast.name, ascending: true)],
        animation: .default)
    var categories: FetchedResults<PodCast>
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
    func idleView(model: PodcastReaderModel) -> some View {
        
        VStack{
            Text("Hello, World!")
            List(model.podCastModel) { category in
            if let name = category.name{
            Text(name)
            }
            HStack{
                TextField("name", text: $viewModel.podCastModel.podCastName).padding()
                TextField("RssFeed", text: $viewModel.podCastModel.rssFeed).padding()
            }
            Button("Save"){
                viewModel.addPodCast(model: model)
            }
        }
        
        
    }
    }
}

