//
//  LogCore.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture
import SwiftUI

import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public struct LogLine: Equatable {

  public init(text: String, color: Color = .primary) {
//  public init(uuid: UUID, text: String, color: Color = .primary) {
//    self.uuid = uuid
    self.text = text
    self.color = color
  }
//  public var id: UUID { uuid }
//  public var uuid: UUID
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

// ----------------------------------------------------------------------------
// MARK: - State, Actions & Environment

public struct LogState: Equatable {
  public init(
    logLevel: LogLevel = LogLevel(rawValue: UserDefaults.standard.string(forKey: "logLevel") ?? "debug") ?? .debug,
    filterBy: LogFilter = LogFilter(rawValue: UserDefaults.standard.string(forKey: "filterBy") ?? "none") ?? .none,
    filterByText: String = UserDefaults.standard.string(forKey: "filterByText") ?? "",
    showTimestamps: Bool = UserDefaults.standard.bool(forKey: "showTimestamps"),
    fontSize: CGFloat = 12
  )
  {
    self.logLevel = logLevel
    self.filterBy = filterBy
    self.filterByText = filterByText
    self.showTimestamps = showTimestamps
    self.fontSize = fontSize
  }
  // State held in User Defaults
  public var filterBy: LogFilter { didSet { UserDefaults.standard.set(filterBy.rawValue, forKey: "filterBy") } }
  public var filterByText: String { didSet { UserDefaults.standard.set(filterByText, forKey: "filterByText") } }
  public var logLevel: LogLevel { didSet { UserDefaults.standard.set(logLevel.rawValue, forKey: "logLevel") } }
  public var showTimestamps: Bool { didSet { UserDefaults.standard.set(showTimestamps, forKey: "showTimestamps") } }

  // normal state
  public var alert: AlertView?
  public var logUrl: URL?
  public var fontSize: CGFloat = 12
  public var logMessages = [LogLine]()
  public var reversed = false
  public var autoRefresh = false
}

public enum LogAction: Equatable {
  // UI actions
  case alertDismissed
  case autoRefreshButton
  case clearButton
  case emailButton
  case filterBy(LogFilter)
  case filterByText(String)
  case fontSize(CGFloat)
  case loadButton
  case logLevel(LogLevel)
  case onAppear(LogLevel)
  case refreshButton
  case reverseButton
  case saveButton
  case timerTicked
  case timestampsButton
  case refreshResultReceived([LogLine])
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

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in

  struct TimerId: Hashable {}

  switch action {
    // ----------------------------------------------------------------------------
    // MARK: - Initialization
    
  case .onAppear(let logLevel):
    let info = getBundleInfo()
    state.logUrl = URL.appSupport.appendingPathComponent(info.domain + "." + info.appName + "/Logs/" + info.appName + ".log" )
    return refreshLog(state, environment)

    // ----------------------------------------------------------------------------
    // MARK: - UI actions
    
  case .autoRefreshButton:
    state.autoRefresh.toggle()
    if state.autoRefresh {
      return Effect.timer(id: TimerId(), every: 0.1, on: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .catchToEffect()
        .map { _ in .timerTicked }
    } else {
      return .cancel(id: TimerId())
    }
    
  case .clearButton:
    state.logMessages.removeAll()
    return .none
    
  case .emailButton:
    state.alert = AlertView(title: "Email: NOT IMPLEMENTED")
    return .none
    
  case .filterBy(let filter):
    state.filterBy = filter

    return refreshLog(state, environment)

  case .filterByText(let text):
    state.filterByText = text
    if state.filterBy != .none {
      return refreshLog(state, environment)
    } else {
      return .none
    }

  case let .fontSize(value):
    state.fontSize = value
    return .none

  case .loadButton:
    if let url = showOpenPanel() {
      state.logUrl = url
      state.logMessages.removeAll()
      return refreshLog(state, environment)
    } else {
      return .none
    }
    
  case .logLevel(let level):
    state.logLevel = level
    return refreshLog(state, environment)

  case .refreshButton:
    return refreshLog(state, environment)

  case .reverseButton:
    state.reversed.toggle()
    return refreshLog(state, environment)

  case .saveButton:
    if let saveURL = showSavePanel() {
      let textArray = state.logMessages.map { $0.text }
      let fileTextArray = textArray.joined(separator: "\n")
      try? fileTextArray.write(to: saveURL, atomically: true, encoding: .utf8)
    }
    return .none
    
  case .timerTicked:
    return refreshLog(state, environment)
    
  case .timestampsButton:
    state.showTimestamps.toggle()
    return refreshLog(state, environment)

    // ----------------------------------------------------------------------------
    // MARK: - Action sent when an Alert is closed
    
  case .alertDismissed:
    state.alert = nil
    return .none

  case .refreshResultReceived(let logMessages):
    
    state.logMessages = logMessages
    return .none
  }
}
//  .debug("-----> LOGVIEWER ")

// ----------------------------------------------------------------------------
// MARK: - Helper functions



func refreshLog(_ state: LogState,  _ environment: LogEnvironment) -> Effect<LogAction, Never>  {
  guard state.logUrl != nil else { fatalError("logUrl is nil") }
  
  let messages = readLogFile(at: state.logUrl!, environment: environment )
    
  return Effect(value: .refreshResultReceived(filterLog(messages, level: state.logLevel, filter: state.filterBy, filterText: state.filterByText, showTimeStamps: state.showTimestamps)))
}

/// Read a Log file
/// - Parameter url:    the URL of the file
/// - Returns:          an array of log entries
func readLogFile(at url: URL, environment: LogEnvironment) -> [LogLine] {
  var messages = [LogLine]()
  
  do {
    // get the contents of the file
    let logString = try String(contentsOf: url, encoding: .ascii)
    // parse it into lines
    let lines = logString.components(separatedBy: "\n").dropLast()
    for line in lines {
      messages.append(LogLine(text: line, color: logLineColor(line)))
    }
    return messages
    
  } catch {
    return messages
  }
}

/// Filter an array of Log entries
/// - Parameters:
///   - messages:       the array
///   - level:          a log level
///   - filter:         a filter type
///   - filterText:     the filter text
///   - showTimes:      whether to show timestamps
/// - Returns:          the filtered array of Log entries
func filterLog(_ messages: [LogLine], level: LogLevel, filter: LogFilter, filterText: String = "", showTimeStamps: Bool = true) -> [LogLine] {
  var lines = [LogLine]()
  var limitedLines = [LogLine]()

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

  if !showTimeStamps {
    for (i, line) in limitedLines.enumerated() {
      limitedLines[i].text = String(line.text.suffix(from: line.text.firstIndex(of: "[") ?? line.text.startIndex))
    }
  }
  return limitedLines
}

/// Determine the color to assign to a Log entry
/// - Parameter text:     the entry
/// - Returns:            a Color
func logLineColor(_ text: String) -> Color {
  if text.contains("[Debug]") { return .gray }
  else if text.contains("[Info]") { return .primary }
  else if text.contains("[Warning]") { return .orange }
  else if text.contains("[Error]") { return .red }
  else { return .primary }
}

/// Display a SavePanel
/// - Returns:       the URL of the selected file or nil
func showSavePanel() -> URL? {
  let savePanel = NSSavePanel()
  savePanel.allowedContentTypes = [.log]
  savePanel.canCreateDirectories = true
  savePanel.isExtensionHidden = false
  savePanel.allowsOtherFileTypes = false
  savePanel.title = "Save the Log"
//  savePanel.nameFieldLabel = "File name:"

  let response = savePanel.runModal()
  return response == .OK ? savePanel.url : nil
}

/// Display an OpenPanel
/// - Returns:        the URL of the selected file or nil
func showOpenPanel() -> URL? {
  let openPanel = NSOpenPanel()
  openPanel.allowedContentTypes = [.log]
  openPanel.allowsMultipleSelection = false
  openPanel.canChooseDirectories = false
  openPanel.canChooseFiles = true
  openPanel.title = "Open an existing Log"
  let response = openPanel.runModal()
  return response == .OK ? openPanel.url : nil
}
