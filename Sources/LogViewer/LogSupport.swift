//
//  LogSupport.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 1/11/22.
//

import Foundation
import ComposableArchitecture
import SwiftUI

import Shared

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums used by LogViewer

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
// MARK: - Pure functions used by LogViewer

/// Return a URL for the Log file (create folder if needed/possible)
/// - Parameters:
///   - domain:     the application domain
///   - appName:    the name of the application
/// - Returns:      a URL for the Log folder
func getLogUrl(for domain: String, appName: String) -> URL? {
  let appFolder = FileManager.appFolder(for: domain + "." + appName + "/Logs")
  let url = appFolder.appendingPathComponent(appName + ".log")

  let fileManager = FileManager()
  if fileManager.fileExists( atPath: url.path ) {
    return url
  }
  return nil
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
      messages.append(LogLine(uuid: environment.uuid(), text: line, color: lineColor(line)))
    }
    return messages

  } catch {
    return nil
  }
}

/// Determine the color to assign to a Log entry
/// - Parameter text:     the entry
/// - Returns:            a Color
func lineColor(_ text: String) -> Color {
  if text.contains("[Debug]") { return .gray }
  else if text.contains("[Info]") { return .primary }
  else if text.contains("[Warning]") { return .orange }
  else if text.contains("[Error]") { return .red }
  else { return .primary }
}

/// Filter an array of Log entries
/// - Parameters:
///   - messages:       the array
///   - level:          a log level
///   - filter:         a filter type
///   - filterText:     the filter text
///   - showTimes:      whether to show timestamps
/// - Returns:          the filtered array of Log entries
func filter(_ messages: IdentifiedArrayOf<LogLine>, level: LogLevel, filter: LogFilter, filterText: String = "", showTimes: Bool = true) -> IdentifiedArrayOf<LogLine> {
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

  if !showTimes {
    for line in limitedLines {
      let startIndex = line.text.firstIndex(of: "[") ?? line.text.startIndex
      limitedLines[id: line.id]?.text = String(line.text[startIndex..<line.text.endIndex])
    }
  }
  return limitedLines
}

/// Display a SavePanel
/// - Returns:       the URL of the selected file or nil
func showSavePanel() -> URL? {
  let savePanel = NSSavePanel()
  savePanel.allowedFileTypes = ["log"]
  savePanel.canCreateDirectories = true
  savePanel.isExtensionHidden = false
  savePanel.allowsOtherFileTypes = false
  savePanel.title = "Save the Log"
  savePanel.message = "Choose a folder and a name to store your Log."
  savePanel.nameFieldLabel = "File name:"

  let response = savePanel.runModal()
  return response == .OK ? savePanel.url : nil
}

/// Display an OpenPanel
/// - Returns:        the URL of the selected file or nil
func showOpenPanel() -> URL? {
  let openPanel = NSOpenPanel()
  openPanel.allowedFileTypes = ["log"]
  openPanel.allowsMultipleSelection = false
  openPanel.canChooseDirectories = false
  openPanel.canChooseFiles = true
  let response = openPanel.runModal()
  return response == .OK ? openPanel.url : nil
}
