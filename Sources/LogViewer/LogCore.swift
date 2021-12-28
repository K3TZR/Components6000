//
//  LogCore.swift
//  Components6000/LogViewer
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture

public enum LogButton: Equatable {
  case showTimestamps
  case apiView
  case email
  case load
  case save
  case refresh
  case clear
}

public enum LogLevel: String, CaseIterable {
  case debug    = "Debug"
  case info     = "Info"
  case warning  = "Warning"
  case error    = "Error"
}

public enum LogFilter: String, CaseIterable {
  case none
  case includes
  case excludes
}

public struct LogState: Equatable {
  public var showTimestamps = false
  public var filterByText = ""
  public var filterBy: LogFilter = .none
  public var logLevel: LogLevel = .debug
  public var fontSize: CGFloat = 12
  
  public init(fontSize: CGFloat = 12) {
    self.fontSize = fontSize
  }
}

public enum LogAction: Equatable {
  // buttons
  case timestampsButton
  case apiViewButton
  case emailButton
  case loadButton
  case saveButton
  case refreshButton
  case clearButton
  // textfield
  case filterByText(String)
  // pickers
  case filterBy(LogFilter)
  case logLevel(LogLevel)
  // stepper
  case fontSize(CGFloat)
}

public struct LogEnvironment {
  
  public init() {}
}

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in
  
  switch action {
    
  case .timestampsButton:
    state.showTimestamps.toggle()
    return .none
    
  case .apiViewButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .emailButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .loadButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .saveButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .refreshButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case .clearButton:
    // TODO
    print("-----> LogCore: NOT IMPLEMENTED \(action)")
    return .none
    
  case let .filterByText(text):
    state.filterByText = text
    return .none
    
  case let .filterBy(filter):
    state.filterBy = filter
    return .none
    
  case let .logLevel(level):
    state.logLevel = level
    return .none
    
  case let .fontSize(value):
    state.fontSize = value
    return .none
  }
}
//  .debug("LOG ")
