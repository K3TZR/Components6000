//
//  LogCore.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture
import Shared
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public struct LogLine: Identifiable, Equatable {

  public init(uuid: UUID, text: String, color: Color = .primary) {
    self.uuid = uuid
    self.text = text
    self.color = color
  }
  public var id: UUID { uuid }
  public var uuid: UUID
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
  public var alert: AlertView?
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
  case refreshButton
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

// ----------------------------------------------------------------------------
// MARK: - Reducer

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in
  
  switch action {
    // ----------------------------------------------------------------------------
    // MARK: - Initialization
    
  case .onAppear(let logLevel):
    let info = getBundleInfo()
    state.logUrl = URL.appSupport.appendingPathComponent(info.domain + "." + info.appName + "/Logs/" + info.appName + ".log" )
    state.logMessages = refreshLog(state, environment)
    return .none

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
    state.logMessages = refreshLog(state, environment)
    return .none

  case .filterByText(let text):
    state.filterByText = text
    state.logMessages = refreshLog(state, environment)
    return .none

  case let .fontSize(value):
    state.fontSize = value
    return .none

  case .loadButton:
    if let url = showOpenPanel() {
      state.logUrl = url
      state.logMessages.removeAll()
      state.logMessages = refreshLog(state, environment)
    }
    return .none
    
  case .logLevel(let level):
    state.logLevel = level
    state.logMessages = refreshLog(state, environment)
    return .none

  case .refreshButton:
    state.logMessages = refreshLog(state, environment)
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
    state.logMessages = refreshLog(state, environment)
    return .none
    
    // ----------------------------------------------------------------------------
    // MARK: - Action sent when an Alert is closed
    
  case .alertDismissed:
    state.alert = nil
    return .none
  }
}
//  .debug("LOGVIEWER ")

// ----------------------------------------------------------------------------
// MARK: - Helper functions

func refreshLog(_ state: LogState, _ environment: LogEnvironment) -> IdentifiedArrayOf<LogLine> {
  if state.logUrl == nil {
    fatalError("logUrl is nil")
  }
  
  if let messages = readLogFile(at: state.logUrl!, environment: environment ) {
    return filterLog(messages, level: state.logLevel, filter: state.filterBy, filterText: state.filterByText, showTimeStamps: state.showTimestamps)
  }
  return IdentifiedArrayOf<LogLine>()
}

/// Read a Log file
/// - Parameter url:    the URL of the file
/// - Returns:          an array of log entries
func readLogFile(at url: URL, environment: LogEnvironment) -> IdentifiedArrayOf<LogLine>? {
  var messages = IdentifiedArrayOf<LogLine>()
  
  do {
    // get the contents of the file
    let logString = try String(contentsOf: url, encoding: .ascii)
    // parse it into lines
    let lines = logString.components(separatedBy: "\n").dropLast()
    for line in lines {
      messages.append(LogLine(uuid: environment.uuid(), text: line, color: logLineColor(line)))
    }
    return messages
    
  } catch {
    return nil
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
func filterLog(_ messages: IdentifiedArrayOf<LogLine>, level: LogLevel, filter: LogFilter, filterText: String = "", showTimeStamps: Bool = true) -> IdentifiedArrayOf<LogLine> {
  var lines = IdentifiedArrayOf<LogLine>()
  var limitedLines = IdentifiedArrayOf<LogLine>()

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
    for line in limitedLines {
//      let startIndex = line.text.firstIndex(of: "[") ?? line.text.startIndex
//      limitedLines[id: line.id]?.text = String(line.text[startIndex..<line.text.endIndex])
      
      limitedLines[id: line.id]?.text = String(line.text.suffix(from: line.text.firstIndex(of: "[") ?? line.text.startIndex))
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
