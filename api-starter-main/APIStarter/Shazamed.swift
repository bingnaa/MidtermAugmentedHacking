//
//  Shazamed.swift
//  APIStarter
//
//  Created by Briana Jones on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
// following this tutorial: https://www.youtube.com/watch?v=KvyQvZYqGL0&t=2s

import Foundation
import UIKit
import ShazamKit

class ViewController: UIViewController, SHSessionDelegate{
    override func viewDidLoad() {
        super.viewDidLoad()
        recognizeSong()
    }
    
    func recognizeSong(){
        let session = SHSession()
        session.delegate = self
        
        //track
        guard let url = Bundle.main.url(forResource: "song", withExtension: "mp3") 
        else{
            print("Failed to get song url")
            return
        }
        
        guard let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length/16))
        else {
            // Handle the error or return if necessary
            return
        }
        
        do {
            try file.read(into: buffer)
            // Continue with your code after reading the data
        } catch {
            // Handle any errors that might occur during the reading process
            print("An error occurred while reading from AVAudioFile: \(error)")
        }
        
        let generator = SHSignatureGenerator()

        do {
            try generator.append(buffer, at: nil)
            // Continue with your code after appending the buffer
        } catch {
            // Handle any errors that might occur during the append process
            print("An error occurred while appending the buffer: \(error)")
        }
    
        let signature = generator.signature()
        
        session.match(signature)
    }
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        let items = match.mediaItems
        items.forEach{item in
            print(item.title ?? "title")
            print(item.artist ?? "artist")
            print(item.artworkURL?.absoluteURL ?? "ArtworkURL")
        }
    }
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        if let error = error{
            print(error)
        }
    }
}
