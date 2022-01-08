//
//  LogCore.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture
import Shared

public enum LogFilter: String, CaseIterable {
  case excludes
  case includes
  case none
}

public struct LogState: Equatable {
  public var filterBy: LogFilter = .none
  public var filterByText = ""
  public var fontSize: CGFloat = 12
  public var logLevel: LogLevel = .debug
  public var showTimestamps = false
  
  public init(fontSize: CGFloat = 12) {
    self.fontSize = fontSize
  }
}

public enum LogAction: Equatable {
  // UI actions
  case apiViewButton
  case clearButton
  case emailButton
  case filterBy(LogFilter)
  case filterByText(String)
  case fontSize(CGFloat)
  case loadButton
  case logLevel(LogLevel)
  case refreshButton
  case saveButton
  case timestampsButton
}

public struct LogEnvironment {
  
  public init() {}
}

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in
  
  switch action {
    
  case .apiViewButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .clearButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .emailButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case let .filterBy(filter):
    state.filterBy = filter
    return .none
    
  case let .filterByText(text):
    state.filterByText = text
    return .none
    
  case let .fontSize(value):
    state.fontSize = value
    return .none

  case .loadButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case let .logLevel(level):
    state.logLevel = level
    return .none

  case .refreshButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .saveButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .timestampsButton:
    state.showTimestamps.toggle()
    return .none
  }
}
//  .debug("LOG ")
