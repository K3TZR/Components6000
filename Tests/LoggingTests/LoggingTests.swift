//
//  LogProxyTests.swift
//  Components6000/SharedTests
//
//  Created by Douglas Adams on 12/2/21.
//

import XCTest
import ComposableArchitecture
import Combine

import XCGWrapper
import LogViewer
import Shared

@testable import Shared
@testable import LogViewer

class LoggingTests: XCTestCase {
  
  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testFolderCreation() {
    let info = getBundleInfo()

    // remove any existing folder
    let logFolderUrl = URL.appSupport.appendingPathComponent( info.domain + "." + info.appName + "/Logs" )
    try? FileManager().removeItem(at: logFolderUrl)

    _ = XCGWrapper(LogProxy.sharedInstance.logPublisher, logLevel: .debug)

    XCTAssert ( FileManager().fileExists(atPath: logFolderUrl.path) == true, "Failed to create File" )

    // remove the folder
    try? FileManager().removeItem(at: logFolderUrl)
    XCTAssert ( FileManager().fileExists(atPath: logFolderUrl.path) == false, "Failed to remove Folder" )
  }

  func testLogProxy() {
    var logMessages = [LogEntry]()
    let logProxy = LogProxy.sharedInstance
    var logSubscription: AnyCancellable?
    
    logSubscription = logProxy.logPublisher
      .sink { entry in
        logMessages.append(entry)
      }
    
    testLogEntries1.forEach { logProxy.log($0.msg, $0.level, $0.function, $0.file, $0.line)}
    XCTAssert( logMessages == testLogEntries1, "Log messages array incorrect" )
    
    logMessages.removeAll()
    
    testLogEntries2.forEach { logProxy.log($0.msg, $0.level, $0.function, $0.file, $0.line)}
    XCTAssert( logMessages == testLogEntries2, "Log messages array incorrect" )
    
    logSubscription = nil
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
  
//  func test
  
  
  func testXCGWrapper() {
    let info = getBundleInfo()

    // get the folder & file urls
    let logFolderUrl = URL.appSupport.appendingPathComponent( info.domain + "." + info.appName + "/Logs" )
    let logFileUrl = logFolderUrl.appendingPathComponent( info.appName + ".log")
    
    // remove the foler (if it exists)
    try? FileManager().removeItem(at: logFolderUrl)
    // prove it's gone
    XCTAssert ( FileManager().fileExists(atPath: logFolderUrl.path) == false )

    let logProxy = LogProxy.sharedInstance
        
    _ = XCGWrapper(LogProxy.sharedInstance.logPublisher, logLevel: .debug)

    let logContent: [String] =
    [
      "[Info] > XCGLogger writing log to: ",
      "[Debug] > XCGWrapperTests-1: debug message",
      "[Info] > XCGWrapperTests-1: info message",
      "[Warning] > XCGWrapperTests-1: warning message",
      "[Error] > XCGWrapperTests-1: error message",
      "",
    ]
    
    // write some log entries
    var logEntry = LogEntry("XCGWrapperTests-1: debug message", .debug, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests-1: info message", .info, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests-1: warning message", .warning, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests-1: error message", .error, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)
    
    // prepare the expected contents
    var logContents = logContent
    logContents[0] += logFolderUrl.appendingPathComponent(info.appName + ".log").absoluteString
    
    sleep(1)
    
    // read the log file and separate into lines
    do {
      let logString = try String(contentsOfFile: logFileUrl.path)
      let logLines = logString.components(separatedBy: .newlines)
      var adjustedLogLines = logLines.map { String($0.dropFirst(24)) }
      adjustedLogLines.remove(at: 0)  // removes the "xctest Version ..." line
      adjustedLogLines.remove(at: 0)  // removes the "XCGLogger Version ..." line
      
      XCTAssert( adjustedLogLines == logContents, "File contents incorrect \n\(adjustedLogLines)\n\(logContents)" )
      
    } catch {
      XCTFail("Failed to read the Log file, \(logFileUrl.path)")
    }
    
    // remove the folder
    do {
      try FileManager().removeItem(at: logFolderUrl)
    } catch {
      XCTFail("Failed to remove file, \(logFolderUrl.path)")
    }
    // prove it's gone
    XCTAssert ( FileManager().fileExists(atPath: logFolderUrl.path) == false )
  }

  func testLogViewer() {
    let info = getBundleInfo()

    // get the folder & file urls
    let logFolderUrl = URL.appSupport.appendingPathComponent( info.domain + "." + info.appName + "/Logs" )
    let logFileUrl = logFolderUrl.appendingPathComponent( info.appName + ".log")
    
    // remove the folder (if it exists)
    try? FileManager().removeItem(at: logFolderUrl)
    // prove it's gone
    XCTAssert ( FileManager().fileExists(atPath: logFolderUrl.path) == false )

    let logProxy = LogProxy.sharedInstance
        
    _ = XCGWrapper(LogProxy.sharedInstance.logPublisher, logLevel: .debug)
    
    // read the log file and separate into lines
    var logLines = [String]()
    var adjustedLogLines = [String]()
    do {
      let logString = try String(contentsOf: logFileUrl)
      logLines = logString.components(separatedBy: .newlines).dropLast()
      adjustedLogLines = logLines.map { String($0.dropFirst(24)) }

    } catch {
      XCTFail("Failed to read the Log file, \(logFileUrl.path)")
    }

    let env = LogEnvironment(uuid: UUID.incrementing)
    let store = TestStore(
      initialState: LogState(logLevel: .debug,
                             filterBy: .none,
                             filterByText: "",
                             showTimestamps: false,
                             fontSize: 12),
      reducer: logReducer,
      environment: env
    )
        

    sleep(1)
    
    // Three entries at this point
    //      "[Info] > xctest Version: 13.2.1 Build: 19566 PID: 19299",
    //      "[Info] > XCGLogger Version: 7.0.1 - Level: Debug",
    //      "[Info] > XCGLogger writing log to: ",
    store.send(.onAppear(.debug)) {
      $0.logUrl = logFileUrl
    }
    
    var expected = IdentifiedArrayOf<LogLine>()
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
      text: adjustedLogLines[0],
      color: lineColor(adjustedLogLines[0])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      text: adjustedLogLines[1],
      color: lineColor(adjustedLogLines[1])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
      text: adjustedLogLines[2],
      color: lineColor(adjustedLogLines[2])))

    store.receive( .refreshButton(logFileUrl, .debug) ) {
      $0.logMessages = expected
    }

    expected.removeAll()
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
      text: logLines[0],
      color: lineColor(logLines[0])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
      text: logLines[1],
      color: lineColor(logLines[1])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
      text: logLines[2],
      color: lineColor(logLines[2])))
    
    store.send(.timestampsButton) {
      $0.showTimestamps.toggle()
    }
    
    // Three entries at this point but with TimeStamps
    //      "2022-02-11 20:01:17.130 [Info] > xctest Version: 13.2.1 Build: 19566 PID: 19299",
    //      "2022-02-11 20:01:17.130 [Info] > XCGLogger Version: 7.0.1 - Level: Debug",
    //      "2022-02-11 20:01:17.131 [Info] > XCGLogger writing log to: ",
    store.receive( .refreshButton(logFileUrl, .debug) ) {
      $0.logMessages = expected
    }

    var logEntry = LogEntry("XCGWrapperTests-2: debug message", .debug, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)
    
    logEntry = LogEntry("XCGWrapperTests-2: info message", .info, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)
    
    logEntry = LogEntry("XCGWrapperTests-2: warning message", .warning, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)
    
    logEntry = LogEntry("XCGWrapperTests-2: error message", .error, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)
    
    sleep(1)
    
    do {
      let logString = try String(contentsOf: logFileUrl)
      logLines = logString.components(separatedBy: .newlines).dropLast()
      adjustedLogLines = logLines.map { String($0.dropFirst(24)) }

    } catch {
      XCTFail("Failed to read the Log file, \(logFileUrl.path)")
    }

    expected.removeAll()
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
      text: logLines[0],
      color: lineColor(logLines[0])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
      text: logLines[1],
      color: lineColor(logLines[1])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
      text: logLines[2],
      color: lineColor(logLines[2])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
      text: logLines[3],
      color: lineColor(logLines[3])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!,
      text: logLines[4],
      color: lineColor(logLines[4])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!,
      text: logLines[5],
      color: lineColor(logLines[5])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000C")!,
      text: logLines[6],
      color: lineColor(logLines[6])))

    // Seven entries at this point with TimeStamps
    //      "2022-02-11 20:01:17.130 [Info] > xctest Version: 13.2.1 Build: 19566 PID: 19299",
    //      "2022-02-11 20:01:17.130 [Info] > XCGLogger Version: 7.0.1 - Level: Debug",
    //      "2022-02-11 20:01:17.131 [Info] > XCGLogger writing log to: ",
    //      "2022-02-11 20:01:17.131 [Debug] > XCGWrapperTests-2: debug message",
    //      "2022-02-11 20:01:17.131 [Info] > XCGWrapperTests-2: info message",
    //      "2022-02-11 20:01:17.131 [Warning] > XCGWrapperTests-2: warning message",
    //      "2022-02-11 20:01:17.131 [Error] > XCGWrapperTests-2: error message",
    store.send(.refreshButton(logFileUrl, .debug)) {
      $0.logMessages = expected
    }
    
    store.send(.logLevel(.info)) {
      $0.logLevel = .info
    }

    expected.removeAll()
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000D")!,
      text: logLines[0],
      color: lineColor(logLines[0])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000E")!,
      text: logLines[1],
      color: lineColor(logLines[1])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000F")!,
      text: logLines[2],
      color: lineColor(logLines[2])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
      text: logLines[4],
      color: lineColor(logLines[4])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
      text: logLines[5],
      color: lineColor(logLines[5])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
      text: logLines[6],
      color: lineColor(logLines[6])))
    
    // Six entries at this point but with TimeStamps
    //      "2022-02-11 20:01:17.130 [Info] > xctest Version: 13.2.1 Build: 19566 PID: 19299",
    //      "2022-02-11 20:01:17.130 [Info] > XCGLogger Version: 7.0.1 - Level: Debug",
    //      "2022-02-11 20:01:17.131 [Info] > XCGLogger writing log to: ",
    //      "2022-02-11 20:01:17.131 [Info] > XCGWrapperTests-2: info message",
    //      "2022-02-11 20:01:17.131 [Warning] > XCGWrapperTests-2: warning message",
    //      "2022-02-11 20:01:17.131 [Error] > XCGWrapperTests-2: error message",

    store.receive( .refreshButton(logFileUrl, .info) ) {
      $0.logMessages = expected
    }
    
    expected.removeAll()
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!,
      text: logLines[5],
      color: lineColor(logLines[5])))
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000001A")!,
      text: logLines[6],
      color: lineColor(logLines[6])))

    // Two entries at this point but with TimeStamps
    //      "2022-02-11 20:01:17.131 [Warning] > XCGWrapperTests-2: warning message",
    //      "2022-02-11 20:01:17.131 [Error] > XCGWrapperTests-: error message",
    store.send(.logLevel(.warning)) {
      $0.logLevel = .warning
    }
    store.receive( .refreshButton(logFileUrl, .warning) ) {
      $0.logMessages = expected
    }

    expected.removeAll()
    expected.append(LogLine(
      uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
      text: logLines[6],
      color: lineColor(logLines[6])))

    // One entry at this point but with TimeStamps
    //      "2022-02-11 20:01:17.131 [Error] > XCGWrapperTests-2: error message",
    store.send(.logLevel(.error)) {
      $0.logLevel = .error
    }
    store.receive( .refreshButton(logFileUrl, .error) ) {
      $0.logMessages = expected
    }
    
    store.send(.fontSize(10)) {
      $0.fontSize = 10
    }
    
    store.send(.fontSize(12)) {
      $0.fontSize = 12
    }
    
    // TODO: add these
    //    store.send(.filterBy(.excludes)) {
    //      $0.filterBy = .excludes
    //    }
    //    store.send(.filterByText("a")) {
    //      $0.filterBy = .excludes
    //    }

    // remove the folder
    do {
      try FileManager().removeItem(at: logFolderUrl)
    } catch {
      XCTFail("Failed to remove file, \(logFolderUrl.path)")
    }
    // prove it's gone
    XCTAssert ( FileManager().fileExists(atPath: logFolderUrl.path) == false )
  }
}

extension UUID {
  /// A deterministic, auto-incrementing "UUID" generator for testing.
  static var incrementing: () -> UUID {
    var uuid = 0
    return {
      defer { uuid += 1 }
      return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
    }
  }
}
