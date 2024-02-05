//
//  Created by odaki_sub on 2024/02/05.
//

import SwiftUI
import AVKit
import Combine


// 参考: https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/HTTPLiveStreaming/HTTPLiveStreaming.html
class VideoPlayerModel: NSObject, ObservableObject, AVAssetDownloadDelegate {
    var downloadSession: AVAssetDownloadURLSession?
    @Published var player: AVPlayer?
    @Published var playerItem: AVPlayerItem?
    
    private let asset = AVURLAsset(url: URL(string:  "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!)
    private var cancellables = Set<AnyCancellable>()
    
    
    func setupAssetDownload() {
        // Create new background session configuration.
        let configuration = URLSessionConfiguration.background(withIdentifier: "hoge")
     
        // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
        downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                    assetDownloadDelegate: self,
                                                    delegateQueue: OperationQueue.main)
        

     
        // Create new AVAssetDownloadTask for the desired asset
        let downloadTask = downloadSession?.makeAssetDownloadTask(asset: asset,
                                                                 assetTitle: "hlsTest",
                                                                 assetArtworkData: nil,
                                                                 options: nil)
        // Start task and begin download
        downloadTask?.resume()
    }
    
    func downloadAndPlayAsset() {
        // Create new AVAssetDownloadTask for the desired asset
        // Passing a nil options value indicates the highest available bitrate should be downloaded
        if let downloadTask = downloadSession?.makeAssetDownloadTask(asset: asset,
                                                                 assetTitle: "hlsTest",
                                                                 assetArtworkData: nil,
                                                                     options: nil) {
            // Start task
            downloadTask.resume()
            
            // Create standard playback items and begin playback
            playerItem = AVPlayerItem(asset: downloadTask.urlAsset)
            player = AVPlayer(playerItem: playerItem)
            addObserver(playerItem: playerItem!)
            addPlayerObserver()
            player?.play()
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        // Iterate through the loaded time ranges
        for value in loadedTimeRanges {
            // Unwrap the CMTimeRange from the NSValue
            let loadedTimeRange = value.timeRangeValue
            // Calculate the percentage of the total expected asset duration
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
            print("Progress: \(percentComplete)")
        }
        percentComplete *= 100
        // Update UI state: post notification, update KVO state, invoke callback, etc.
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        // Do not move the asset from the download location
        print("Download Completed: \(location.relativePath)")
        UserDefaults.standard.set(location.relativePath, forKey: "hoge")
    }
    
    func addObserver(playerItem: AVPlayerItem) {
        playerItem.publisher(for: \.status).sink { status in
            print("AVPlayerItem status changed: \(status)")
        }
        .store(in: &cancellables)
    }
    
    func addPlayerObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            .sink{ _ in
                print("PlayerItem completed")
            }
            .store(in: &cancellables)
    }
    
    func playOfflineAsset() {
        guard let assetPath = UserDefaults.standard.value(forKey: "hlsTest") as? String else {
            print("Present Error: No offline version of this asset available")
            return
        }
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(assetPath)
        let asset = AVURLAsset(url: assetURL)
        if let cache = asset.assetCache, cache.isPlayableOffline {
            let playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            player?.play()
        } else {
            print("Present Error: No playable version of this asset exists offline")
        }
    }
}
