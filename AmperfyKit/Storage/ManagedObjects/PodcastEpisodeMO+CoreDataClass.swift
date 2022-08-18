//
//  PodcastEpisodeMO+CoreDataClass.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 25.06.21.
//  Copyright (c) 2021 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import CoreData

@objc(PodcastEpisodeMO)
public final class PodcastEpisodeMO: AbstractPlayableMO {

}

extension PodcastEpisodeMO: CoreDataIdentifyable {
   
    static var identifierKey: KeyPath<PodcastEpisodeMO, String?> {
        return \PodcastEpisodeMO.title
    }
    
    static var publishedDateSortedFetchRequest: NSFetchRequest<PodcastEpisodeMO> {
        let fetchRequest: NSFetchRequest<PodcastEpisodeMO> = PodcastEpisodeMO.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(PodcastEpisodeMO.publishDate), ascending: false),
            NSSortDescriptor(key: "id", ascending: true, selector: #selector(NSString.localizedStandardCompare))
        ]
        return fetchRequest
    }

}
