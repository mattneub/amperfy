//
//  DuplicateEntitiesResolver.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 30.05.22.
//  Copyright (c) 2022 Maximilian Bauer. All rights reserved.
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
import os.log

public class DuplicateEntitiesResolver {
    
    private let log = OSLog(subsystem: "Amperfy", category: "DuplicateEntitiesResolver")
    private let persistentStorage: PersistentStorage
    private let activeDispatchGroup = DispatchGroup()
    private let mainFlowSemaphore = DispatchSemaphore(value: 1)
    private var isRunning = false
    private var isActive = false
    
    init(persistentStorage: PersistentStorage) {
        self.persistentStorage = persistentStorage
    }
    
    public func start() {
        isRunning = true
        if !isActive {
            isActive = true
            resolveDuplicatesInBackground()
        }
    }
    
    public func stopAndWait() {
        isRunning = false
        activeDispatchGroup.wait()
    }
    
    private func resolveDuplicatesInBackground() {
        DispatchQueue.global().async {
            self.activeDispatchGroup.enter()
            os_log("start", log: self.log, type: .info)
            
            // only check for duplicates on Ampache API, Subsonic does not have genre ids
            if self.isRunning, self.persistentStorage.loginCredentials?.backendApi == .ampache {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: Genre.typeName).filter{ $0.id != "" }
                    library.resolveGenresDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            if self.isRunning {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: Artist.typeName).filter{ $0.id != "" }
                    library.resolveArtistsDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            if self.isRunning {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: Album.typeName).filter{ $0.id != "" }
                    library.resolveAlbumsDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            if self.isRunning {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: Song.typeName).filter{ $0.id != "" }
                    library.resolveSongsDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            if self.isRunning {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: PodcastEpisode.typeName).filter{ $0.id != "" }
                    library.resolvePodcastEpisodesDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            if self.isRunning {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: Podcast.typeName).filter{ $0.id != "" }
                    library.resolvePodcastsDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            if self.isRunning {
                self.mainFlowSemaphore.wait()
                self.persistentStorage.persistentContainer.performBackgroundTask() { (context) in
                    defer { self.mainFlowSemaphore.signal() }
                    let library = LibraryStorage(context: context)
                    let duplicates = library.findDuplicates(for: Playlist.typeName).filter{ $0.id != "" }
                    library.resolvePlaylistsDuplicates(duplicates: duplicates)
                    library.saveContext()
                 }
            }
            
            os_log("stopped", log: self.log, type: .info)
            self.isActive = false
            self.activeDispatchGroup.leave()
        }
    }
    
}
