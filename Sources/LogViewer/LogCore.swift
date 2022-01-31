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
  public init(domain: String,
              appName: String,
//              backName: String = "Back",
              fontSize: CGFloat = 12
  )
  {
    self.domain = domain
    self.appName = appName
//    self.backName = backName
    self.fontSize = fontSize
    self.logLevel = LogLevel(rawValue: UserDefaults.standard.string(forKey: "logLevel") ?? "debug") ?? .debug
    self.filterBy = LogFilter(rawValue: UserDefaults.standard.string(forKey: "filterBy") ?? "none") ?? .none
    self.filterByText = UserDefaults.standard.string(forKey: "filterByText") ?? ""
    self.showTimestamps = UserDefaults.standard.bool(forKey: "showTimestamps")
  }
  // State held in User Defaults
  public var filterBy: LogFilter { didSet { UserDefaults.standard.set(filterBy.rawValue, forKey: "filterBy") } }
  public var filterByText: String { didSet { UserDefaults.standard.set(filterByText, forKey: "filterByText") } }
  public var logLevel: LogLevel { didSet { UserDefaults.standard.set(logLevel.rawValue, forKey: "logLevel") } }
  public var showTimestamps: Bool { didSet { UserDefaults.standard.set(showTimestamps, forKey: "showTimestamps") } }

  // normal state
//  public var backName: String
  public var domain: String
  public var alert: AlertView?
  public var appName: String
  public var logUrl: URL?
  public var fontSize: CGFloat = 12
  public var logMessages = IdentifiedArrayOf<LogEntry>()
  public var forceUpdate = false
  
}

public enum LogAction: Equatable {
  // UI actions
  case alertDismissed
//  case backButton
  case clearButton
  case emailButton
  case filterBy(LogFilter)
  case filterByText(String)
  case fontSize(CGFloat)
  case loadButton
  case logLevel(LogLevel)
  case onAppear
  case refreshButton(URL)
  case saveButton
  case timestampsButton
}

public struct LogEnvironment {
  
  public init() {}
}

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in
  
  switch action {
    
  case .alertDismissed:
    state.alert = nil
    return .none
    
//  case .backButton:
//    // handled downstream
//    return .none
//
  case .clearButton:
    state.logMessages.removeAll()
    return .none
    
  case .emailButton:
    state.alert = AlertView(title: "Email: NOT IMPLEMENTED")
    return .none
    
  case let .filterBy(filter):
    state.filterBy = filter
    return Effect(value: .refreshButton(state.logUrl!))

  case let .filterByText(text):
    state.filterByText = text
    return Effect(value: .refreshButton(state.logUrl!))

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
          state.logMessages.append(LogEntry(text: item, color: lineColor(item)))
        }

      } catch {
        return .none
      }
    }
    return .none
    
  case let .logLevel(level):
    state.logLevel = level
    return Effect(value: .refreshButton(state.logUrl!))

  case .onAppear:
    if let url = getLogUrl(for: state.domain, appName: state.appName) {
      state.logUrl = url
    }
    return Effect(value: .refreshButton(state.logUrl!))

  case let .refreshButton(url):
    if let messages = readLogFile(at: url ) {
      state.logMessages = filter(messages, level: state.logLevel, filter: state.filterBy, filterText: state.filterByText, showTimes: state.showTimestamps)
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
    return Effect(value: .refreshButton(state.logUrl!))
  }
}
//  .debug("LOG ")
