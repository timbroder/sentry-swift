//
//  Stacktrace.swift
//  SentrySwift
//
//  Created by Josh Holtz on 7/22/16.
//
//

import Foundation

// A class used to represent an exception: `sentry.interfaces.stacktrace.Stacktrace`
@objc(SentryStacktrace) public final class Stacktrace: NSObject {
    public let frames: [Frame]
    
    internal convenience init?(appleCrashTreadBacktraceDict: [String: AnyObject]?, binaryImages: [BinaryImage]?) {
        guard let appleCrashTreadBacktraceDict = appleCrashTreadBacktraceDict, let binaryImages = binaryImages else {
            return nil
        }
        
        let frames = (appleCrashTreadBacktraceDict["contents"] as? [[String: AnyObject]])?
            .flatMap({ Frame(appleCrashFrameDict: $0, binaryImages: binaryImages) })
        self.init(frames: frames)
        
    }
    
    @objc public init(frames: [Frame]?) {
        self.frames = frames ?? []
    }
    
}

extension Stacktrace: EventSerializable {
    internal typealias SerializedType = SerializedTypeDictionary
    internal var serialized: SerializedType {
        #if swift(>=3.0)
        return [:]
            .set("frames", value: frames.reversed().map({ $0.serialized }))
        #else
        return [:]
            .set("frames", value: frames.reverse().map({ $0.serialized }))
        #endif
    }
}

extension Stacktrace {
    
    public static func convertReactNativeStacktrace(_ stacktrace: [[String: AnyObject]]?) -> Stacktrace? {
        guard let stacktrace = stacktrace else { return nil }
        
        var frames: [Frame] = []
        for frame in stacktrace {
            if frame["methodName"] == nil {
                continue
            }
            if let file = frame["file"] as? String {
                if file == "[native code]" {
                    continue
                }
                #if swift(>=3.0)
                    let simpleFilename = (file as NSString).lastPathComponent.components(separatedBy: "?")[0]
                #else
                    let simpleFilename = (file as NSString).lastPathComponent.componentsSeparatedByString("?")[0]
                #endif
                if let methodName = frame["methodName"] as? String,
                    let lineNumber = frame["lineNumber"] as? Int,
                    let column = frame["column"] as? Int {
                    let frame = Frame(fileName: "/\(simpleFilename)", function: methodName, module: nil, line: lineNumber, column: column)
                    frame.platform = "javascript"
                    frames.append(frame)
                }
            }
        }
        
        return Stacktrace(frames: frames)
    }
    
}
