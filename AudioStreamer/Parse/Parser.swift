//
//  Parser.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

/// The `Parser` is a concrete implementation of the `Parsing` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsing {    
    // MARK: - Parsing props
    
    public internal(set) var dataFormat: AVAudioFormat?

    public var packetsCount: Int {
        objc_sync_enter(self)
        let result = packets.count
        objc_sync_exit(self)
        return result
    }

    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormat else {
            return nil
        }
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packetsCount))
    }
    
    // MARK: - Properties
    
    /// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    public internal(set) var frameCount: UInt64 = 0
    
    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    public internal(set) var packetCount: UInt64 = 0
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?
    
    // MARK: - Lifecycle
    
    /// Initializes an instance of the `Parser`
    ///
    /// - Throws: A `ParserError.streamCouldNotOpen` meaning a file stream instance could not be opened
    public init() throws {
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }

    deinit {
        if let streamID = streamID {
            AudioFileStreamClose(streamID)
        }
    }

    // MARK: - Methods

    public func appendPacket(data: Data, description: AudioStreamPacketDescription?) {
        objc_sync_enter(self)
        packets.append((data, description))
        objc_sync_exit(self)
    }

    public func packet(at index: Int) -> (Data, AudioStreamPacketDescription?) {
        objc_sync_enter(self)
        let result = packets[index]
        objc_sync_exit(self)
        return result
    }
    
    public func parse(data: Data) throws {
        let streamID = self.streamID!
        let count = data.count
        _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
            guard result == noErr else {
                throw ParserError.failedToParseBytes(result)
            }
        }
    }

    private var packets = [(Data, AudioStreamPacketDescription?)]()
}
