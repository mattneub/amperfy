//
//  CacheFileManager.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 24.04.24.
//  Copyright (c) 2019 Maximilian Bauer. All rights reserved.
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
import UniformTypeIdentifiers

public class MimeFileConverter {
    static let filenameExtensionUnknown = "unknown"
    static let mimeTypeUnknown = "application/octet-stream"
    
    static let mimeTypes = [
        "ogg": "audio/ogg",
        "ogx": "application/ogg",
        "flac": "audio/x-flac" // the case "audio/flac" is already covered by UTType
    ]
    
    static let iOSIncompatibleMimeTypes = [
        "audio/x-ms-wma",
        "audio/ogg",
        "application/ogg",
        mimeTypeUnknown
    ]
    
    static let conversionNeededMimeTypes = [
        "audio/x-flac": "audio/flac",
        "audio/m4a": "audio/mp4"
    ]
    
    static func convertToValidMimeTypeWhenNeccessary(mimeType: String) -> String {
        let mimeTypeLowerCased = mimeType.lowercased()
        return Self.conversionNeededMimeTypes[mimeTypeLowerCased] ?? mimeTypeLowerCased
    }
    
    static func isMimeTypePlayableOniOS(mimeType: String) -> Bool {
        return !iOSIncompatibleMimeTypes.contains(where: { $0 == mimeType.lowercased() })
    }
    
    static func getMIMEType(filenameExtension: String?) -> String? {
        guard let filenameExtension = filenameExtension?.lowercased(),
                  filenameExtension != "raw"
        else { return nil }
        
        let mimeType = UTType(filenameExtension: filenameExtension)?.preferredMIMEType ??
                       mimeTypes[filenameExtension] ??
                       Self.mimeTypeUnknown
        return mimeType
    }
    
    static func getFilenameExtension(mimeType: String?) -> String {
        guard let mimeType = mimeType?.lowercased()
        else { return Self.filenameExtensionUnknown }
        
        let fileExt = UTType(mimeType: mimeType)?.preferredFilenameExtension ??
                      mimeTypes.findKey(forValue: mimeType) ??
                      Self.filenameExtensionUnknown
        return fileExt
    }
}

public class CacheFileManager {
    
    private static var inst: CacheFileManager?
    public static var shared: CacheFileManager {
        if inst == nil { inst = CacheFileManager() }
        return inst!
    }
    
    private let fileManager = FileManager.default
    // Get the URL to the app container's 'Library' directory.
    private var amperfyLibraryDirectory: URL?

    public func moveItemToTempDirectoryWithUniqueName(at: URL) throws -> URL {
        // Get the URL to the app container's 'tmp' directory.
        var tmpFileURL = fileManager.temporaryDirectory
        tmpFileURL.appendPathComponent(UUID().uuidString, isDirectory: false)
        try fileManager.moveItem(at: at, to: tmpFileURL)
        return tmpFileURL
    }
    
    public func moveExcludedFromBackupItem(at: URL, to: URL) throws {
        let subDir = to.deletingLastPathComponent()
        if createDirectoryIfNeeded(at: subDir) {
            try? markItemAsExcludedFromBackup(at: subDir)
        }
        if fileManager.fileExists(atPath: to.path) {
            try? self.removeItem(at: to)
        }
        try fileManager.moveItem(at: at, to: to)
        try markItemAsExcludedFromBackup(at: to)
    }
    
    @discardableResult
    public func createDirectoryIfNeeded(at url: URL) -> Bool {
        guard !fileManager.fileExists(atPath: url.path) else { return false }
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return true
    }
    
    public func removeItem(at: URL) throws {
        try fileManager.removeItem(at: at)
    }
    
    private func getOrCreateAmperfyDirectory() -> URL?  {
        var amperfyDir: URL? = amperfyLibraryDirectory
        if amperfyDir == nil,
           // the action to get Amperfy's library directory takes long -> save it in cache
           let bundleIdentifier = Bundle.main.bundleIdentifier,
           // Get the URL to the app container's 'Library' directory.
           var url = try? fileManager.url(for: .libraryDirectory,
                                   in: .userDomainMask,
                                   appropriateFor: nil,
                                   create: false)
        {
            // Append the bundle identifier to the retrieved URL.
            url.appendPathComponent(bundleIdentifier, isDirectory: true)
            if createDirectoryIfNeeded(at: url) {
                try? markItemAsExcludedFromBackup(at: url)
            }
            amperfyDir = url
            amperfyLibraryDirectory = url
        }
        return amperfyDir
    }
        
    private func getOrCreateSubDirectory(subDirectoryName: String) -> URL?  {
        guard let url = getOrCreateAmperfyDirectory()?.appendingPathComponent(subDirectoryName, isDirectory: true) else { return nil }
        if createDirectoryIfNeeded(at: url) {
            try? markItemAsExcludedFromBackup(at: url)
        }
        return url
    }
    
    public func deletePlayableCache() {
        if let absSongsDir = getAbsoluteAmperfyPath(relFilePath: Self.songsDir) {
            try? fileManager.removeItem(at: absSongsDir)
        }
        if let absEpisodesDir = getAbsoluteAmperfyPath(relFilePath: Self.episodesDir) {
            try? fileManager.removeItem(at: absEpisodesDir)
        }
        if let absEmbeddedArtworksDir = getAbsoluteAmperfyPath(relFilePath: Self.embeddedArtworksDir) {
            try? fileManager.removeItem(at: absEmbeddedArtworksDir)
        }
    }
    
    public func deleteRemoteArtworkCache() {
        if let absArtworksDir = getAbsoluteAmperfyPath(relFilePath: Self.artworksDir) {
            try? fileManager.removeItem(at: absArtworksDir)
        }
    }
    
    public var playableCacheSize: Int64 {
        var bytes = Int64(0)
        if let absSongsDir = getAbsoluteAmperfyPath(relFilePath: Self.songsDir) {
            bytes += directorySize(url: absSongsDir)
        }
        if let absEpisodesDir = getAbsoluteAmperfyPath(relFilePath: Self.episodesDir) {
            bytes += directorySize(url: absEpisodesDir)
        }
        return bytes
    }
    
    private static let artworkFileExtension = "png"
    private static let lyricsFileExtension = "xml"
    private static let songsDir = URL(string: "songs")!
    private static let episodesDir = URL(string: "episodes")!
    private static let artworksDir = URL(string: "artworks")!
    private static let embeddedArtworksDir = URL(string: "embedded-artworks")!
    private static let lyricsDir = URL(string: "lyrics")!

    public func getOrCreateAbsoluteSongsDirectory() -> URL?  {
        return getOrCreateSubDirectory(subDirectoryName: Self.songsDir.path)
    }
    
    public func getOrCreateAbsolutePodcastEpisodesDirectory() -> URL?  {
        return getOrCreateSubDirectory(subDirectoryName: Self.episodesDir.path)
    }
    
    public func getOrCreateAbsoluteArtworksDirectory() -> URL?  {
        return getOrCreateSubDirectory(subDirectoryName: Self.artworksDir.path)
    }
    
    public func getOrCreateAbsoluteEmbeddedArtworksDirectory() -> URL?  {
        return getOrCreateSubDirectory(subDirectoryName: Self.embeddedArtworksDir.path)
    }
    
    public func getOrCreateAbsoluteLyricsDirectory() -> URL?  {
        return getOrCreateSubDirectory(subDirectoryName: Self.lyricsDir.path)
    }
    
    public struct PlayableCacheInfo {
        let url: URL
        let id: String
        let fileType: String
        let mimeType: String?
        let relFilePath: URL?
    }
    
    public func getCachedSongs() -> [PlayableCacheInfo] {
        var URLs = [URL]()
        var cacheInfo = [PlayableCacheInfo]()
        if let songsDir = getOrCreateAbsoluteSongsDirectory() {
            URLs = contentsOfDirectory(url: songsDir)
        }
        for url in URLs {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
            guard isDirectoryResourceValue.isDirectory == nil || isDirectoryResourceValue.isDirectory == false else {
                continue
            }
            
            let fileName = url.lastPathComponent
            var id = fileName
            let pathExtension = url.pathExtension
            var mimeType: String?
            if !pathExtension.isEmpty {
                id = (fileName as NSString).deletingPathExtension
                mimeType = MimeFileConverter.getMIMEType(filenameExtension: pathExtension)
            }
            cacheInfo.append(PlayableCacheInfo(url: url, id: id, fileType: pathExtension, mimeType: mimeType, relFilePath: Self.songsDir.appendingPathComponent(fileName)))
        }
        return cacheInfo
    }
    
    public func getCachedEpisodes() -> [PlayableCacheInfo] {
        var URLs = [URL]()
        var cacheInfo = [PlayableCacheInfo]()
        if let episodesDir = getOrCreateAbsolutePodcastEpisodesDirectory() {
            URLs = contentsOfDirectory(url: episodesDir)
        }
        for url in URLs {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
            guard isDirectoryResourceValue.isDirectory == nil || isDirectoryResourceValue.isDirectory == false else {
                continue
            }
            
            let fileName = url.lastPathComponent
            var id = fileName
            let pathExtension = url.pathExtension
            var mimeType: String?
            if !pathExtension.isEmpty {
                id = (fileName as NSString).deletingPathExtension
                mimeType = MimeFileConverter.getMIMEType(filenameExtension: pathExtension)
            }
            cacheInfo.append(PlayableCacheInfo(url: url, id: id, fileType: pathExtension, mimeType: mimeType, relFilePath: Self.episodesDir.appendingPathComponent(fileName)))
        }
        return cacheInfo
    }

    public struct EmbeddedArtworkCacheInfo {
        let url: URL
        let id: String
        let isSong: Bool
        let relFilePath: URL?
    }
    
    public func getCachedEmbeddedArtworks() -> [EmbeddedArtworkCacheInfo] {
        var cacheInfo = [EmbeddedArtworkCacheInfo]()
        if let embeddedArtworksDir = getOrCreateAbsoluteEmbeddedArtworksDirectory() {
            cacheInfo.append(contentsOf: getCachedEmbeddedArtworks(in: embeddedArtworksDir.appendingPathComponent(Self.songsDir.path), isSong: true))
            cacheInfo.append(contentsOf: getCachedEmbeddedArtworks(in: embeddedArtworksDir.appendingPathComponent(Self.episodesDir.path), isSong: false))
        }
        return cacheInfo
    }
    
    private func getCachedEmbeddedArtworks(in dir: URL, isSong: Bool) -> [EmbeddedArtworkCacheInfo] {
        let URLs = contentsOfDirectory(url: dir)
        var cacheInfo = [EmbeddedArtworkCacheInfo]()
        for url in URLs {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
            
            guard isDirectoryResourceValue.isDirectory == nil || isDirectoryResourceValue.isDirectory == false else {
                continue
            }

            
            let fileName = url.lastPathComponent
            var id = fileName
            let pathExtension = url.pathExtension
            if !pathExtension.isEmpty {
                id = (fileName as NSString).deletingPathExtension
            }
            let relFilePath = isSong ?
                Self.embeddedArtworksDir.appendingPathComponent(Self.songsDir.path).appendingPathComponent(fileName) :
                Self.embeddedArtworksDir.appendingPathComponent(Self.episodesDir.path).appendingPathComponent(fileName)
            cacheInfo.append(EmbeddedArtworkCacheInfo(url: url, id: id, isSong: isSong, relFilePath: relFilePath))
        }
        return cacheInfo
    }
    
    public struct ArtworkCacheInfo {
        let url: URL
        let id: String
        let type: String
        let relFilePath: URL?
    }
    
    public func getCachedArtworks() -> [ArtworkCacheInfo] {
        var cacheInfo = [ArtworkCacheInfo]()
        if let artworksDir = getOrCreateAbsoluteArtworksDirectory() {
            cacheInfo.append(contentsOf: getCachedArtworks(in: artworksDir, type: ""))
        }
        return cacheInfo
    }
    
    private func getCachedArtworks(in dir: URL, type: String) -> [ArtworkCacheInfo] {
        let URLs = contentsOfDirectory(url: dir)
        var cacheInfo = [ArtworkCacheInfo]()
        for url in URLs {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
           
            if isDirectoryResourceValue.isDirectory == true {
                let newType = url.lastPathComponent
                cacheInfo.append(contentsOf: getCachedArtworks(in: url, type: newType))
            } else {
                let fileName = url.lastPathComponent
                var id = fileName
                let pathExtension = url.pathExtension
                if !pathExtension.isEmpty {
                    id = (fileName as NSString).deletingPathExtension
                }
                let relFilePath = !type.isEmpty ?
                    Self.artworksDir.appendingPathComponent(type).appendingPathComponent(fileName) :
                    Self.artworksDir.appendingPathComponent(fileName)
                cacheInfo.append(ArtworkCacheInfo(url: url, id: id, type: type, relFilePath: relFilePath))
            }
        }
        return cacheInfo
    }

    public struct LyricsCacheInfo {
        let url: URL
        let id: String
        let isSong: Bool
        let relFilePath: URL?
    }
    
    public func getCachedLyrics() -> [LyricsCacheInfo] {
        var cacheInfo = [LyricsCacheInfo]()
        if let lyricsDir = getOrCreateAbsoluteLyricsDirectory() {
            cacheInfo.append(contentsOf: getCachedLyrics(in: lyricsDir.appendingPathComponent(Self.songsDir.path), isSong: true))
            cacheInfo.append(contentsOf: getCachedLyrics(in: lyricsDir.appendingPathComponent(Self.episodesDir.path), isSong: false))
        }
        return cacheInfo
    }
    
    private func getCachedLyrics(in dir: URL, isSong: Bool) -> [LyricsCacheInfo] {
        let URLs = contentsOfDirectory(url: dir)
        var cacheInfo = [LyricsCacheInfo]()
        for url in URLs {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
            
            guard isDirectoryResourceValue.isDirectory == nil || isDirectoryResourceValue.isDirectory == false else {
                continue
            }

            let fileName = url.lastPathComponent
            var id = fileName
            let pathExtension = url.pathExtension
            if !pathExtension.isEmpty {
                id = (fileName as NSString).deletingPathExtension
            }
            let relFilePath = isSong ?
                Self.lyricsDir.appendingPathComponent(Self.songsDir.path).appendingPathComponent(fileName) :
                Self.lyricsDir.appendingPathComponent(Self.episodesDir.path).appendingPathComponent(fileName)
            cacheInfo.append(LyricsCacheInfo(url: url, id: id, isSong: isSong, relFilePath: relFilePath))
        }
        return cacheInfo
    }

    public func createRelPath(forLyricsOf song: Song) -> URL? {
        guard let ownerRelFilePath = createRelPath(for: song)
        else { return nil }

        let lyricsRelFilePath = ownerRelFilePath.deletingPathExtension().appendingPathExtension(Self.lyricsFileExtension)
        return Self.lyricsDir.appendingPathComponent(lyricsRelFilePath.path)
    }
    
    public func createRelPath(for playable: AbstractPlayable) -> URL? {
        guard !playable.playableManagedObject.id.isEmpty else { return nil }
        
        let fileExtension: String = {
            if let mimeType = playable.contentTypeTranscoded {
                return MimeFileConverter.getFilenameExtension(mimeType: mimeType)
            } else if let mimeType = playable.contentType {
                return MimeFileConverter.getFilenameExtension(mimeType: mimeType)
            } else {
                return MimeFileConverter.filenameExtensionUnknown
            }
        }()

        if playable.isSong {
            return Self.songsDir.appendingPathComponent(playable.playableManagedObject.id).appendingPathExtension(fileExtension)
        } else {
            return Self.episodesDir.appendingPathComponent(playable.playableManagedObject.id).appendingPathExtension(fileExtension)
        }
    }
    
    public func createRelPath(for artwork: Artwork) -> URL? {
        guard !artwork.managedObject.id.isEmpty else { return nil }
        if !artwork.type.isEmpty {
            return Self.artworksDir.appendingPathComponent(artwork.type).appendingPathComponent(artwork.managedObject.id).appendingPathExtension(Self.artworkFileExtension)
        } else {
            return Self.artworksDir.appendingPathComponent(artwork.managedObject.id).appendingPathExtension(Self.artworkFileExtension)
        }
    }
    
    public func createRelPath(for embeddedArtwork: EmbeddedArtwork) -> URL? {
        guard let owner = embeddedArtwork.owner,
              let ownerRelFilePath = createRelPath(for: owner)
        else { return nil }
        
        let embeddedArtworkOwnerRelFilePath = ownerRelFilePath.deletingPathExtension().appendingPathExtension(Self.artworkFileExtension)
        return Self.embeddedArtworksDir.appendingPathComponent(embeddedArtworkOwnerRelFilePath.path)
    }
    
    public func getAmperfyPath() -> String? {
        return getOrCreateAmperfyDirectory()?.path
    }
    
    public func getAbsoluteAmperfyPath(relFilePath: URL) -> URL? {
        guard let amperfyDir = getOrCreateAmperfyDirectory() else { return nil }
        return amperfyDir.appendingPathComponent(relFilePath.path)
    }
    
    public func fileExits(relFilePath: URL) -> Bool {
        guard let absFilePath = getOrCreateAmperfyDirectory()?.appendingPathComponent(relFilePath.path) else { return false }
        return fileManager.fileExists(atPath: absFilePath.path)
    }
    
    public func writeDataExcludedFromBackup(data: Data, to: URL) throws {
        let subDir = to.deletingLastPathComponent()
        if createDirectoryIfNeeded(at: subDir) {
            try? markItemAsExcludedFromBackup(at: subDir)
        }
        try data.write(to: to, options: [.atomic])
        try markItemAsExcludedFromBackup(at: to)
    }
    
    public func markItemAsExcludedFromBackup(at: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        // Apply those values to the URL.
        var url = at
        try url.setResourceValues(values)
    }
    
    public func contentsOfDirectory(url: URL) -> [URL] {
        let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
        return contents ?? [URL]()
    }
    
    public func directorySize(url: URL) -> Int64 {
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
        } catch {
            return 0
        }

        var size: Int64 = 0

        for url in contents {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
        
            if isDirectoryResourceValue.isDirectory == true {
                size += directorySize(url: url)
            } else {
                if let fileSize = getFileSize(url: url) {
                    size += fileSize
                }
            }
        }
        return size
    }
    
    public func getFileSize(url: URL) -> Int64? {
        guard let fileSizeResourceValue = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let intSize = fileSizeResourceValue.fileSize
        else { return nil }
        return Int64(intSize)
    }
    
    /// maximum file size that is allowed to load directly into memory to avoid memory overflow
    public static let maxFileSizeToHandleDataInMemory = 50_000_000
    
    public func getFileDataIfNotToBig(url: URL?, maxFileSize: Int = maxFileSizeToHandleDataInMemory) -> Data? {
        guard let fileURL = url,
              let fileSize = getFileSize(url: fileURL),
              fileSize < maxFileSize
        else { return nil }
        return try? Data(contentsOf: fileURL)
    }
    
}
