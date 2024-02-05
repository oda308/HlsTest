//
//  ContentView.swift
//  HlsTest
//
//  Created by odaki_sub on 2024/02/05.
//

import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject var model = VideoPlayerModel()
    @State private var onLaunched = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("HLS Test")
                VideoPlayer(player: model.player)
                NavigationLink("次のページ") {
                    SecondaryView(model: model)
                }
            }
            .padding()
            .onAppear {
                if !onLaunched {
                    onLaunched = true
                    model.setupAssetDownload()
                    model.downloadAndPlayAsset()
                }
            }
        }
    }
}

struct SecondaryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: VideoPlayerModel
    @State var path: String?
    
    var body: some View {
            VStack {
                Text("Secondary")
                if path != "" {
                    VideoPlayer(player: model.player)
                } else {
                    Text("File is not downloaded")
                }
                Button("戻る") {
                    dismiss()
                }
            }
            .padding()
            .onAppear {
                print("Check downloaded file...")
                path = UserDefaults.standard.object(forKey: "hlsTest") as? String
                if path != nil{
                    model.playOfflineAsset()
                }
                
            }
        
    }
}
