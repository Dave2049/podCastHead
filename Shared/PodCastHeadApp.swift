//
//  PodCastHeadApp.swift
//  Shared
//
//  Created by David Schnurr on 24.01.21.
//

import SwiftUI

@main
struct PodCastHeadApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
