//
//  DiscoveryTests.swift
//  Components6000/DiscoveryTests
//
//  Created by Douglas Adams on 11/14/21.
//

import XCTest
import ComposableArchitecture
import Combine

//import Shared
import LogProxy
import XCGWrapper

@testable import XCGWrapper

class XCGWrapperTests: XCTestCase {
//  let logProxy = LogProxy.sharedInstance
  let fileManager = FileManager.default
  let domain = "net.k3tzr"
  let appName = "XCGWrapperTests"
  
  func testFolderCreation() {
    let logProxy = LogProxy.sharedInstance

    // remove any existing folder
    let logFolderUrl = URL.appSupport.appendingPathComponent( domain + "." + appName + "/Logs" )
    try? fileManager.removeItem(at: logFolderUrl)

    let wrapper = XCGWrapper(logPublisher: logProxy.logPublisher, appName: appName, domain: domain)

    // remove the folder
    try? fileManager.removeItem(at: logFolderUrl)
    XCTAssert ( fileManager.fileExists(atPath: logFolderUrl.path) == false, "Failed to remove Folder" )
  }

  func testLogEntry() {
    let logProxy = LogProxy.sharedInstance

    // remove any existing folder
    let logFolderUrl = URL.appSupport.appendingPathComponent( domain + "." + appName + "/Logs" )
    try? fileManager.removeItem(at: logFolderUrl)

    let wrapper = XCGWrapper(logPublisher: logProxy.logPublisher, appName: appName, domain: domain)

    var logEntry = LogEntry("XCGWrapperTests: debug message", .debug, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: verbose message", .verbose, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: info message", .info, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: warning message", .warning, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: error message", .error, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)
    
    // prepare the expected contents
    var logContents = logContent
    logContents[0] += logFolderUrl.appendingPathComponent(appName + ".log").absoluteString
    
    // read the log file and separate into lines
    do {
      let logString = try String(contentsOf: logFolderUrl.appendingPathComponent( "/" + appName + ".log"), encoding: .utf8)
      let logLines = logString.components(separatedBy: .newlines)
      var adjustedLogLines = logLines.map { String($0.dropFirst(24)) }
      adjustedLogLines.remove(at: 0)  // removes the "xctest Version ..." line
      adjustedLogLines.remove(at: 0)  // removes the "XCGLogger Version ..." line

      XCTAssert( adjustedLogLines == logContents, "File contents incorrect" )

    } catch {
      XCTFail("Failed to read the Log file")
    }
    
    // remove the folder
    do {
      try fileManager.removeItem(at: logFolderUrl)
    } catch {
      XCTFail("Failed to remove folder")
    }
    XCTAssert ( fileManager.fileExists(atPath: logFolderUrl.path) == false )
  }

  func testLogLevel() {
    let logProxy = LogProxy.sharedInstance

    // remove any existing folder
    let logFolderUrl = URL.appSupport.appendingPathComponent( domain + "." + appName + "/Logs" )
    try? fileManager.removeItem(at: logFolderUrl)

    let wrapper = XCGWrapper(logPublisher: logProxy.logPublisher, appName: appName, domain: domain, logLevel: .warning)

    var logEntry = LogEntry("XCGWrapperTests: debug message", .debug, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: verbose message", .verbose, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: info message", .info, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: warning message", .warning, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    logEntry = LogEntry("XCGWrapperTests: error message", .error, #function, #file, #line)
    logProxy.logPublisher.send(logEntry)

    // prepare the expected contents
    var logContents = logContent2
    logContents[0] += logFolderUrl.appendingPathComponent(appName + ".log").absoluteString

    // read the log file and separate into lines
    do {
      let logString = try String(contentsOf: logFolderUrl.appendingPathComponent( "/" + appName + ".log"), encoding: .utf8)
      let logLines = logString.components(separatedBy: .newlines)
      let adjustedLogLines = logLines.map { String($0.dropFirst(24)) }

      XCTAssert( adjustedLogLines == logContents, "File contents incorrect" )

    } catch {
      XCTFail("Failed to read the Log file")
    }

    // remove the folder
    do {
      try fileManager.removeItem(at: logFolderUrl)
      XCTAssert ( fileManager.fileExists(atPath: logFolderUrl.path) == false )

    } catch {
      XCTFail("Failed to remove folder")
    }
  }

  let logContent: [String] =
  [
    "[Info] > XCGLogger writing log to: ",
    "[Debug] > XCGWrapperTests: debug message",
    "[Verbose] > XCGWrapperTests: verbose message",
    "[Info] > XCGWrapperTests: info message",
    "[Warning] > XCGWrapperTests: warning message",
    "[Error] > XCGWrapperTests: error message",
    "",
  ]
  let logContent2: [String] =
  [
    "[Info] > XCGLogger writing log to: ",
    "[Warning] > XCGWrapperTests: warning message",
    "[Error] > XCGWrapperTests: error message",
    "",
  ]
}
