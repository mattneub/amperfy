//
//  PodcastMO+CoreDataClass.swift
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

@objc(PodcastMO)
public final class PodcastMO: AbstractLibraryEntityMO {

}

extension PodcastMO: CoreDataIdentifyable {
    
    static var identifierKey: KeyPath<PodcastMO, String?> {
        return \PodcastMO.title
    }
    
    func passOwnership(to targetPodcast: PodcastMO) {
        let episodesCopy = episodes?.compactMap{ $0 as? PodcastEpisodeMO }
        episodesCopy?.forEach{
            $0.podcast = targetPodcast
        }
    }
    
}
