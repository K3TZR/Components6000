//
//  LogProxy.swift
//  Components6000/LogProxy
//
//  Created by Douglas Adams on 12/12/21.
//

import Foundation
import Combine

public enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error
}

public struct LogEntry: Equatable {
  public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
    guard lhs.msg == rhs.msg else { return false }
    guard lhs.level == rhs.level else { return false }
    guard lhs.level == rhs.level else { return false }
    guard lhs.function.description == rhs.function.description else { return false }
    guard lhs.file.description == rhs.file.description else { return false }
    guard lhs.line == rhs.line else { return false }
    return true
  }
  
  public var msg: String
  public var level: LogLevel
  public var function: StaticString
  public var file: StaticString
  public var line: Int
  
  public init(_ msg: String, _ level: LogLevel, _ function: StaticString, _ file: StaticString, _ line: Int ) {
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
  public var publishLog = true

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  // "private" prevents others from calling init()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Publish a log message
  /// - Parameters:
  ///   - msg:         a message
  ///   - level:       the log level
  ///   - function:    the function performing the logging
  ///   - file:        the file performing the logging
  ///   - line:        the line performing the logging
  public func log(_ msg: String, _ level: LogLevel, _ function: StaticString, _ file: StaticString, _ line: Int ) {

    if publishLog {
      // publish for use by a logging module
      logPublisher.send( LogEntry(msg, level, function, file, line) )
    } else {
      // print to the console
      print("\(msg), level = \(level.rawValue)")
    }
  }

  /// Publish a log message
  /// - Parameters:
  ///   - logEntry:        a LogEntry struct
//  public func publish(_ logEntry: LogEntry ) {
//    
//    if publishLog {
//      // publish for use by a logging module
//      logPublisher.send(logEntry)
//    } else {
//      // print to the console
//      print("\(logEntry.msg), level = \(logEntry.level.rawValue)")
//    }
//  }
}
