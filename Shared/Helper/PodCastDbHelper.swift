//
//  PodCastDbHelper.swift
//  PodCastHead
//
//  Created by David Schnurr on 06.03.21.
//

import Foundation
import CoreData
struct PodCastDBHelper{
    static func fetchPodCastByFeed(context: NSManagedObjectContext, rssFeed: String) throws -> [PodCast]{
        let podCastsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PodCast")
            podCastsFetch.predicate = NSPredicate(format: "rssFeed == %@", rssFeed)
            return try context.fetch(podCastsFetch) as! [PodCast]
    }
}
