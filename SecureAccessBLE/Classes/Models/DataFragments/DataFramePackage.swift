//
//  DataFramePackage.swift
//  TransportTest
//
//  Created by Sebastian Stüssel on 20.08.15.
//  Copyright (c) 2015 Rocket Apes. All rights reserved.
//

import UIKit

///Creates and holds data Frames for a SIDMessage
class DataFramePackage: NSObject {
    /// Date frame list
    var frames = [DataFrame]()
    /// start index
    var currentIndex = 0
    /// Dateframe current used
    var currentFrame: DataFrame? {
        if frames.isEmpty || currentIndex > frames.count-1 {
            return nil
        } else {
            let frame = frames[currentIndex]
            return frame
        }
    }
    
    /// The message data the SIDMessage contains
    var message: NSData {
        let data = NSMutableData()
        
        for frame in frames {
            data.appendData(frame.message)
        }
        return data
    }
    
    /**
     convenience initialization point
     
     - parameter messageData: the message data SIDMessage contains
     - parameter frameSize:   the data frame size
     
     - returns: Data frame package objec
     */
    convenience init(messageData: NSData, frameSize: Int) {
        var frameStack = [DataFrame]()
        let messageSize = messageData.length
        var numberOfFrames = messageSize / frameSize
        if numberOfFrames == 0 || messageSize % frameSize != 0 {
            numberOfFrames += 1
        }
        
        //Create the frames
        for i in 0 ..< numberOfFrames {
            //Configure frame type
            let type = DataFramePackage.configureType(i, numberOfFrames: numberOfFrames)
            let sequence = i
            let location = i * frameSize
            let frameLength: Int = {
                if location + frameSize > messageSize {
                    return messageSize - location
                } else {
                    return frameSize
                }
                }()
            
            let messagePart = messageData.subdataWithRange(NSMakeRange(location, frameLength))
            let frame = DataFrame(message: messagePart, type: type, sequenceNumber: UInt8(sequence), completeMessageLength: UInt16(messageData.length))
            frameStack.append(frame)
        }

        self.init()
        self.frames = frameStack
    }
    
//MARK: - Helper
    private class func configureType(sequence: Int, numberOfFrames: Int) -> DataFrameType {
        /// Start type as NotValid
        var type = DataFrameType.NotValid
        if sequence == 0 && numberOfFrames == 1 {
            type = .Single
        } else if sequence == 0 {
            type = .Sop
        } else if sequence == numberOfFrames - 1 {
            type = .Eop
        } else {
            type = .Frag
        }
        return type
    }
}
