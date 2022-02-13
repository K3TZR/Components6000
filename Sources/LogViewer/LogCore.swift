//
//  LogCore.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture
import Shared
import SwiftUI

public struct LogState: Equatable {
  public init(logLevel: LogLevel = LogLevel(rawValue: UserDefaults.standard.string(forKey: "logLevel") ?? "debug") ?? .debug,
              filterBy: LogFilter = LogFilter(rawValue: UserDefaults.standard.string(forKey: "filterBy") ?? "none") ?? .none,
              filterByText: String = UserDefaults.standard.string(forKey: "filterByText") ?? "",
              showTimestamps: Bool = UserDefaults.standard.bool(forKey: "showTimestamps"),
              fontSize: CGFloat = 12
  )
  {
//    self.domain = domain
//    self.appName = appName
    self.fontSize = fontSize
    self.logLevel = logLevel
    self.filterBy = filterBy
    self.filterByText = filterByText
    self.showTimestamps = showTimestamps
  }
  // State held in User Defaults
  public var filterBy: LogFilter { didSet { UserDefaults.standard.set(filterBy.rawValue, forKey: "filterBy") } }
  public var filterByText: String { didSet { UserDefaults.standard.set(filterByText, forKey: "filterByText") } }
  public var logLevel: LogLevel { didSet { UserDefaults.standard.set(logLevel.rawValue, forKey: "logLevel") } }
  public var showTimestamps: Bool { didSet { UserDefaults.standard.set(showTimestamps, forKey: "showTimestamps") } }

  // normal state
//  public var domain: String
  public var alert: AlertView?
//  public var appName: String
  public var logUrl: URL?
  public var fontSize: CGFloat = 12
  public var logMessages = IdentifiedArrayOf<LogLine>()
  public var forceUpdate = false
  
}

public enum LogAction: Equatable {
  // UI actions
  case alertDismissed
  case clearButton
  case emailButton
  case filterBy(LogFilter)
  case filterByText(String)
  case fontSize(CGFloat)
  case loadButton
  case logLevel(LogLevel)
  case onAppear(LogLevel)
  case refreshButton(URL, LogLevel)
  case saveButton
  case timestampsButton
}

public struct LogEnvironment {
  public init(
    queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .main },
    uuid: @escaping () -> UUID = { .init() }
  )
  {
    self.queue = queue
    self.uuid = uuid
  }
  var queue: () -> AnySchedulerOf<DispatchQueue>
  var uuid: () -> UUID
}

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in
  
  switch action {
    // ----------------------------------------------------------------------------
    // MARK: - Initialization
    
  case .onAppear(let logLevel):
    let info = getBundleInfo()
    state.logUrl = URL.appSupport.appendingPathComponent(info.domain + "." + info.appName + "/Logs/" + info.appName + ".log" )
    return Effect(value: .refreshButton(state.logUrl!, logLevel))

    // ----------------------------------------------------------------------------
    // MARK: - UI actions
    
  case .clearButton:
    state.logMessages.removeAll()
    return .none
    
  case .emailButton:
    state.alert = AlertView(title: "Email: NOT IMPLEMENTED")
    return .none
    
  case .filterBy(let filter):
    state.filterBy = filter
    return Effect(value: .refreshButton(state.logUrl!, state.logLevel))

  case .filterByText(let text):
    state.filterByText = text
    return Effect(value: .refreshButton(state.logUrl!, state.logLevel))

  case let .fontSize(value):
    state.fontSize = value
    return .none

  case .loadButton:
    if let url = showOpenPanel() {
      state.logMessages.removeAll()
      do {
        let fileString = try String(contentsOf: url)
        let fileArray = fileString.components(separatedBy: "\n")
        for item in fileArray {
          state.logMessages.append(LogLine(uuid: environment.uuid(), text: item, color: lineColor(item)))
        }

      } catch {
        return .none
      }
    }
    return .none
    
  case .logLevel(let level):
    state.logLevel = level
    return Effect(value: .refreshButton(state.logUrl!, level))

  case .refreshButton(let logUrl, let level):
    if let messages = readLogFile(at: logUrl, environment: environment ) {
      state.logMessages = filter(messages, level: level, filter: state.filterBy, filterText: state.filterByText, showTimes: state.showTimestamps)
    }
    return .none
    
  case .saveButton:
    if let saveURL = showSavePanel() {
      let textArray = state.logMessages.map { $0.text }
      let fileTextArray = textArray.joined(separator: "\n")
      try? fileTextArray.write(to: saveURL, atomically: true, encoding: .utf8)
    }
    return .none
    
  case .timestampsButton:
    state.showTimestamps.toggle()
    if state.logUrl != nil {
      return Effect(value: .refreshButton(state.logUrl!, state.logLevel))
    }
    return .none
    
    // ----------------------------------------------------------------------------
    // MARK: - Action sent when an Alert is closed
    
  case .alertDismissed:
    state.alert = nil
    return .none
  }
}
//  .debug("LOGVIEWER ")
