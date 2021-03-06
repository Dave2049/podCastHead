//
//  ContentView.swift
//  PodCastHead
//
//  Created by David Schnurr on 24.01.21.
//

import SwiftUI

struct ContentView: View {
    
 /*   var testModel = PodPlayerModel(imageUrl: URL(string: "https://www.buchpodcast.de/kapitel-fuenf/Kapitel_Eins_Folge_B5.mp3")!, mp3Url: URL(string: "https://hwcdn.libsyn.com/p/c/0/e/c0e1b0b925bd42b4/Kapitel_Eins_Folge_63.mp3?c_id=94444499&cs_id=94444499&expiration=1612034584&hwt=b50b1e7e037ae9f91fe84a7b8bf86313")!, text: "Test Title", pub: nil) */
    var testRss = RssReaderEpisodeModel(base: BaseRssReader(feed: URL(string: "https://buchpodcast.libsyn.com/rss")!, name: "BuchPodcast"), episodes: nil, selectedEpisode: nil)
    
    var body: some View {
     //   PodPlayerView(viewModel: PodPlayerViewModel(model: testModel))
       
      /*      GeometryReader{ reader in
                RssReaderView(viewModel: RssReaderViewModel(model: testRss)).environmentObject(EnvReader(size: reader.size))
                
            }
        .listStyle(SidebarListStyle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)*/
        
        SplitView()
    }
}


struct SplitView: View {
    var testRss = RssReaderEpisodeModel(base: BaseRssReader(feed: URL(string: "https://buchpodcast.libsyn.com/rss")!, name: "BuchPodcast"), episodes: nil, selectedEpisode: nil)
    var
    
    //
    var body: some View {
        #if os(macOS)
        macOsContentView()
        #elseif os(iOS)
        iosOsContentView()
        #endif
    }
    fileprivate func macOsContentView() -> some View {
        return NavigationView{
            /*RssReaderView(viewModel: RssEpisodeViewModel(model: testRss))
                .frame(minWidth: 250, idealWidth: 250, maxWidth: 300, maxHeight: .infinity).listStyle(SidebarListStyle()).frame(minWidth: 250, maxWidth: 350) */
            PodCastRssReaderView(viewModel: <#PodCastReaderVM#>).environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
    }
    
    fileprivate func iosOsContentView() -> some View {
        PodCastRssReaderView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
      //  RssReaderView(viewModel: RssEpisodeViewModel(model: testRss))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
