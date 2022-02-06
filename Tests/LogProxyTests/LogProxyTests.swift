//
//  LogProxyTests.swift
//  Components6000/SharedTests
//
//  Created by Douglas Adams on 12/2/21.
//

import XCTest
import ComposableArchitecture
import Combine

import Shared

@testable import Shared

class LogProxyTests: XCTestCase {
  
  var logMessages = [LogEntry]()
  var proxy = LogProxy.sharedInstance
  var logCancellable: AnyCancellable?
  let log = LogProxy.sharedInstance.log

  func testProxy() {
    
    logCancellable = proxy.logPublisher
      .sink { [self] entry in
        logMessages.append(entry)
      }

    testLogEntries1.forEach { log($0.msg, $0.level, $0.function, $0.file, $0.line)}
    
    XCTAssert( logMessages == testLogEntries1, "Log messages array incorrect" )
    
    logMessages.removeAll()
    
    testLogEntries2.forEach { log($0.msg, $0.level, $0.function, $0.file, $0.line)}
    
    XCTAssert( logMessages == testLogEntries2, "Log messages array incorrect" )

  }

  var testLogEntries1: [LogEntry] = [
    
    LogEntry("This is a DEBUG entry", .debug, "Function1", "File1", 100),
    LogEntry("This is a INFO entry", .info, "Function2", "File2", 200),
    LogEntry("This is a WARNING entry", .warning, "Function3", "File3", 300),
    LogEntry("This is a ERROR entry", .error, "Function4", "File4", 400)
  ]

  var testLogEntries2: [LogEntry] = [
    
    LogEntry("This is a ERROR entry", .error, "Function4", "File4", 500),
    LogEntry("This is a WARNING entry", .warning, "Function3", "File3", 600),
    LogEntry("This is a INFO entry", .info, "Function2", "File2", 700),
    LogEntry("This is a DEBUG entry", .debug, "Function1", "File1", 800)
  ]
}
