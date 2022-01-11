//
//  LogCore.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture
import Shared
import SwiftUI

public struct LogEntry: Identifiable, Equatable {

  public init(text: String, color: Color = .primary) {
    self.text = text
    self.color = color
  }
  public var id = UUID()
  public var text: String
  public var color: Color
}

public enum LogFilter: String, CaseIterable, Identifiable {
  case excludes
  case includes
  case none
  case prefix

  public var id: String { self.rawValue }
}

public struct LogState: Equatable {
  public init(domain: String,
              appName: String,
              fontSize: CGFloat = 12
  )
  {
    self.domain = domain
    self.appName = appName
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
  case apiViewButton
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
    
  case .apiViewButton:
    // handled downstream
    return .none

  case .clearButton:
    state.logMessages.removeAll()
    return .none
    
  case .emailButton:
    // TODO
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
    // TODO
    state.alert = AlertView(title: "Load: NOT IMPLEMENTED")
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
    // TODO
    state.alert = AlertView(title:"Save: NOT IMPLEMENTED")
    return .none
    
  case .timestampsButton:
    state.showTimestamps.toggle()
    return Effect(value: .refreshButton(state.logUrl!))
  }
}
//  .debug("LOG ")

// ----------------------------------------------------------------------------
// MARK: - Private pure functions

private func getLogUrl(for domain: String, appName: String) -> URL? {
  let appFolder = FileManager.appFolder(for: domain + "." + appName + "/Logs")
  let url = appFolder.appendingPathComponent(appName + ".log")

  let fileManager = FileManager()
  if fileManager.fileExists( atPath: url.path ) {
    return url
  }
  return nil
}

private func readLogFile(at url: URL) -> IdentifiedArrayOf<LogEntry>? {
  var messages = IdentifiedArrayOf<LogEntry>()

  func lineColor(_ text: String) -> Color {
    if text.contains("[Debug]") {
      return .gray
    } else if  text.contains("[Info]") {
      return .primary
    } else if  text.contains("[Warning]") {
      return .orange
    } else if  text.contains("[Error]") {
      return .red
    } else {
      return .primary
    }
  }

  do {
    // get the contents of the file
    let logString = try String(contentsOf: url, encoding: .ascii)
    // parse it into lines
    let lines = logString.components(separatedBy: "\n")
    for line in lines {
      messages.append(LogEntry(text: line, color: lineColor(line)))
    }
    return messages

  } catch {
    return nil
  }
}

private func filter(_ messages: IdentifiedArrayOf<LogEntry>, level: LogLevel, filter: LogFilter, filterText: String = "", showTimes: Bool = true) -> IdentifiedArrayOf<LogEntry> {
  var lines = IdentifiedArrayOf<LogEntry>()
  var limitedLines = IdentifiedArrayOf<LogEntry>()

  // filter the log entries
  switch level {
  case .debug:     lines = messages
  case .info:      lines = messages.filter { $0.text.contains(" [Error] ") || $0.text.contains(" [Warning] ") || $0.text.contains(" [Info] ") }
  case .warning:   lines = messages.filter { $0.text.contains(" [Error] ") || $0.text.contains(" [Warning] ") }
  case .error:     lines = messages.filter { $0.text.contains(" [Error] ") }
  }

  switch filter {
  case .none:       limitedLines = lines
  case .prefix:     limitedLines = lines.filter { $0.text.contains(" > " + filterText) }
  case .includes:   limitedLines = lines.filter { $0.text.contains(filterText) }
  case .excludes:   limitedLines = lines.filter { !$0.text.contains(filterText) }
  }

  if !showTimes {
    for line in limitedLines {
      let startIndex = line.text.firstIndex(of: "[") ?? line.text.startIndex
      limitedLines[id: line.id]?.text = String(line.text[startIndex..<line.text.endIndex])
    }
  }
  return limitedLines
}
