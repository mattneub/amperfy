//
//  MusicFolderMO+CoreDataProperties.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 27.05.21.
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


extension MusicFolderMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MusicFolderMO> {
        return NSFetchRequest<MusicFolderMO>(entityName: "MusicFolder")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var directoryCount: Int16
    @NSManaged public var songCount: Int16
    @NSManaged public var directories: NSOrderedSet?
    @NSManaged public var songs: NSOrderedSet?
    @NSManaged public var isCached: Bool

    static let relationshipKeyPathsForPrefetching = [
        #keyPath(MusicFolderMO.directories),
    ]

}

// MARK: Generated accessors for directories
extension MusicFolderMO {

    @objc(insertObject:inDirectoriesAtIndex:)
    @NSManaged public func insertIntoDirectories(_ value: DirectoryMO, at idx: Int)

    @objc(removeObjectFromDirectoriesAtIndex:)
    @NSManaged public func removeFromDirectories(at idx: Int)

    @objc(insertDirectories:atIndexes:)
    @NSManaged public func insertIntoDirectories(_ values: [DirectoryMO], at indexes: NSIndexSet)

    @objc(removeDirectoriesAtIndexes:)
    @NSManaged public func removeFromDirectories(at indexes: NSIndexSet)

    @objc(replaceObjectInDirectoriesAtIndex:withObject:)
    @NSManaged public func replaceDirectories(at idx: Int, with value: DirectoryMO)

    @objc(replaceDirectoriesAtIndexes:withDirectories:)
    @NSManaged public func replaceDirectories(at indexes: NSIndexSet, with values: [DirectoryMO])

    @objc(addDirectoriesObject:)
    @NSManaged public func addToDirectories(_ value: DirectoryMO)

    @objc(removeDirectoriesObject:)
    @NSManaged public func removeFromDirectories(_ value: DirectoryMO)

    @objc(addDirectories:)
    @NSManaged public func addToDirectories(_ values: NSOrderedSet)

    @objc(removeDirectories:)
    @NSManaged public func removeFromDirectories(_ values: NSOrderedSet)

}

// MARK: Generated accessors for songs
extension MusicFolderMO {

    @objc(insertObject:inSongsAtIndex:)
    @NSManaged public func insertIntoSongs(_ value: SongMO, at idx: Int)

    @objc(removeObjectFromSongsAtIndex:)
    @NSManaged public func removeFromSongs(at idx: Int)

    @objc(insertSongs:atIndexes:)
    @NSManaged public func insertIntoSongs(_ values: [SongMO], at indexes: NSIndexSet)

    @objc(removeSongsAtIndexes:)
    @NSManaged public func removeFromSongs(at indexes: NSIndexSet)

    @objc(replaceObjectInSongsAtIndex:withObject:)
    @NSManaged public func replaceSongs(at idx: Int, with value: SongMO)

    @objc(replaceSongsAtIndexes:withSongs:)
    @NSManaged public func replaceSongs(at indexes: NSIndexSet, with values: [SongMO])

    @objc(addSongsObject:)
    @NSManaged public func addToSongs(_ value: SongMO)

    @objc(removeSongsObject:)
    @NSManaged public func removeFromSongs(_ value: SongMO)

    @objc(addSongs:)
    @NSManaged public func addToSongs(_ values: NSOrderedSet)

    @objc(removeSongs:)
    @NSManaged public func removeFromSongs(_ values: NSOrderedSet)

}
