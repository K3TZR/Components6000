//
//  XCGWrapper.swift
//  
//
//  Created by Douglas Adams on 12/20/21.
//

import Foundation
import Combine
import XCGLogger

import LogProxy

public final class XCGWrapper {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  var log: XCGLogger {
    get { _objectQ.sync { _log } }
    set { _objectQ.sync(flags: .barrier) {_log = newValue }}}
  
  private var _logCancellable: AnyCancellable?
  
  private var _defaultLogUrl: URL!
  private var _defaultFolder: String!
  private var _log: XCGLogger!
  private var _objectQ = DispatchQueue(label: "XCGWrapper.objectQ", attributes: [.concurrent])

  private let kMaxLogFiles: UInt8  = 10
  private let kMaxTime: TimeInterval = 60 * 60 // 1 Hour

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(logPublisher: PassthroughSubject<LogEntry, Never>, appName: String, domain: String, logLevel: XCGLogger.Level = .verbose) {
    _log = XCGLogger(identifier: appName, includeDefaultDestinations: false)
    
    let defaultLogName = appName + ".log"
    _defaultFolder = URL.appSupport.path + "/" + domain + "." + appName + "/Logs"
    
#if DEBUG
    // for DEBUG only
    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: appName + ".systemDestination")
    
    // Optionally set some configuration options
    systemDestination.outputLevel           = logLevel
    systemDestination.showFileName          = false
    systemDestination.showFunctionName      = false
    systemDestination.showLevel             = true
    systemDestination.showLineNumber        = false
    systemDestination.showLogIdentifier     = false
    systemDestination.showThreadName        = false
    
    // Add the destination to the logger
    log.add(destination: systemDestination)
#endif
    
    // Get / Create a file log destination
    if let logs = setupLogFolder(appName: appName, domain: domain) {
      let fileDestination = AutoRotatingFileDestination(writeToFile: logs.appendingPathComponent(defaultLogName),
                                                        identifier: appName + ".autoRotatingFileDestination",
                                                        shouldAppend: true,
                                                        appendMarker: "- - - - - App was restarted - - - - -")
      
      // Optionally set some configuration options
      fileDestination.outputLevel             = logLevel
      fileDestination.showDate                = true
      fileDestination.showFileName            = false
      fileDestination.showFunctionName        = false
      fileDestination.showLevel               = true
      fileDestination.showLineNumber          = false
      fileDestination.showLogIdentifier       = false
      fileDestination.showThreadName          = false
      fileDestination.targetMaxLogFiles       = kMaxLogFiles
      fileDestination.targetMaxTimeInterval   = kMaxTime
      
      // Process this destination in the background
      fileDestination.logQueue = XCGLogger.logQueue
      
      // Add the destination to the logger
      log.add(destination: fileDestination)
      
      // Add basic app info, version info etc, to the start of the logs
      log.logAppDetails()
      
      // format the date (only effects the file logging)
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
      dateFormatter.locale = Locale.current
      log.dateFormatter = dateFormatter
      
      _defaultLogUrl = URL(fileURLWithPath: _defaultFolder + "/" + defaultLogName)

      _logCancellable = logPublisher
        .sink { [self] entry in
          // Log Handler to support XCGLogger
          switch entry.level {
            
          case .verbose:  log.verbose(entry.msg, functionName: entry.function, fileName: entry.file, lineNumber: entry.line )
          case .debug:    log.debug(entry.msg, functionName: entry.function, fileName: entry.file, lineNumber: entry.line)
          case .info:     log.info(entry.msg, functionName: entry.function, fileName: entry.file, lineNumber: entry.line)
          case .warning:  log.warning(entry.msg, functionName: entry.function, fileName: entry.file, lineNumber: entry.line)
          case .error:    log.error(entry.msg, functionName: entry.function, fileName: entry.file, lineNumber: entry.line)
          }
        }
    } else {
      fatalError("Logging failure:, unable to find / create Log folder")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func setupLogFolder(appName: String, domain: String) -> URL? {
    createAsNeeded(domain + "." + appName + "/Logs")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func createAsNeeded(_ folder: String) -> URL? {
    let fileManager = FileManager.default
    let folderUrl = URL.appSupport.appendingPathComponent( folder )
    // try to create it
    do {
      try fileManager.createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
    } catch {
      return nil
    }
    return folderUrl
  }
}


extension URL {
  static var appSupport : URL { return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first! }
}