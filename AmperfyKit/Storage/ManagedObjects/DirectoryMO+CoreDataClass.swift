//
//  DirectoryMO+CoreDataClass.swift
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

@objc(DirectoryMO)
public final class DirectoryMO: AbstractLibraryEntityMO {

    static var nameSortedFetchRequest: NSFetchRequest<DirectoryMO> {
        let fetchRequest: NSFetchRequest<DirectoryMO> = DirectoryMO.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(DirectoryMO.name), ascending: true)
        ]
        return fetchRequest
    }

    static func getSearchPredicate(searchText: String) -> NSPredicate {
        var predicate: NSPredicate = NSPredicate.alwaysTrue
        if searchText.count > 0 {
            predicate = NSPredicate(format: "%K contains[cd] %@", #keyPath(DirectoryMO.name), searchText)
        }
        return predicate
    }

}

extension DirectoryMO: CoreDataIdentifyable {
    
    static var identifierKey: KeyPath<DirectoryMO, String?> {
        return \DirectoryMO.name
    }
    
}
