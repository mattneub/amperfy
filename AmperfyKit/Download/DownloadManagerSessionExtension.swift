//
//  DownloadManagerSessionExtension.swift
//  AmperfyKit
//
//  Created by Maximilian Bauer on 21.07.21.
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
import os.log

extension DownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {
        
    func fetch(url: URL, download: Download, context: NSManagedObjectContext) {
        let library = LibraryStorage(context: context)
        let task = urlSession.downloadTask(with: url)
        download.url = url
        library.saveContext()
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let requestUrl = downloadTask.originalRequest?.url?.absoluteString else { return }
        
        var downloadError: DownloadError?
        var downloadedData: Data?
        do {
            let data = try Data(contentsOf: location)
            if data.count > 0 {
                downloadedData = data
            } else {
                downloadError = .emptyFile
            }
        } catch let error {
            downloadError = .fetchFailed
            os_log("Could not get downloaded file from disk: %s", log: self.log, type: .error, error.localizedDescription)
        }
        
        self.persistentStorage.context.performAndWait {
            let library = LibraryStorage(context: self.persistentStorage.context)
            guard let download = library.getDownload(url: requestUrl) else { return }
            if let activeError = downloadError {
                self.finishDownload(download: download, context: self.persistentStorage.context, error: activeError)
            } else if let data = downloadedData {
                self.finishDownload(download: download, context: self.persistentStorage.context, data: data)
            } else {
                self.finishDownload(download: download, context: self.persistentStorage.context, error: .emptyFile)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil, let requestUrl = task.originalRequest?.url?.absoluteString else { return }
        self.persistentStorage.context.performAndWait {
            let library = LibraryStorage(context: self.persistentStorage.context)
            guard let download = library.getDownload(url: requestUrl) else { return }
            self.finishDownload(download: download, context: self.persistentStorage.context, error: .fetchFailed)
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let requestUrl = downloadTask.originalRequest?.url?.absoluteString else { return }
        
        self.persistentStorage.persistentContainer.performBackgroundTask() { context in
            let library = LibraryStorage(context: context)
            guard let download = library.getDownload(url: requestUrl) else { return }
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            guard progress > download.progress, (download.progress == 0.0) || (progress > download.progress + 0.1) else { return }
            download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            download.totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
            library.saveContext()
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log("URLSession urlSessionDidFinishEvents", log: self.log, type: .info)
        if let completionHandler = backgroundFetchCompletionHandler {
            os_log("Calling application backgroundFetchCompletionHandler", log: self.log, type: .info)
            completionHandler()
            backgroundFetchCompletionHandler = nil
        }
    }
    
}
