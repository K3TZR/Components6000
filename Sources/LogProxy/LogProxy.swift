//
//  LogProxy.swift
//  Components6000/LogProxy
//
//  Created by Douglas Adams on 12/12/21.
//

import Foundation
import Combine

public enum MessageLevel: String {
    case debug
    case verbose
    case info
    case warning
    case error
}

public struct LogEntry {
  public var msg: String
  public var level: MessageLevel
  public var function: StaticString
  public var file: StaticString
  public var line: Int
  
  public init(_ msg: String, _ level: MessageLevel, _ function: StaticString, _ file: StaticString, _ line: Int ) {
    self.msg = msg
    self.level = level
    self.function = function
    self.file = file
    self.line = line
  }
}

final public class LogProxy {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public static var sharedInstance = LogProxy()
  public var logPublisher = PassthroughSubject<LogEntry, Never>()
  public var publishLog = false

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  // "private" prevents others from calling init()
  private init() {}

//    _logCancellable = logPublisher
//      .sink { logEntry in
//      }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Publish a log message
  /// - Parameters:
  ///   - logEntry:        a LogEntry struct
  public func publish(_ logEntry: LogEntry ) {

    #if DEBUG
      // print to the console
      print("\(logEntry.msg), level = \(logEntry.level.rawValue)")
    #else
    if publishLog {
      // publish for use by a logging module
      logPublisher.send(logEntry)
    } else {
      // print to the console
      print("\(logEntry.msg), level = \(logEntry.level.rawValue)")
    }
    #endif
  }
}
