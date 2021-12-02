//
//  LogCore.swift
//  TestDiscoveryPackage/Log
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
  
  public init(fontSize: CGFloat) {
    self.fontSize = fontSize
  }
}

public enum LogAction: Equatable {
  case buttonTapped(LogButton)
  case filterByTextChanged(String)
  case filterByChanged(LogFilter)
  case logLevelChanged(LogLevel)
  case fontSizeChanged(CGFloat)
}

public struct LogEnvironment {
  
  public init() {}
}

public let logReducer = Reducer<LogState, LogAction, LogEnvironment> {
  state, action, environment in
  
  switch action {
    
  case let .buttonTapped(button):
    switch button {
    case .showTimestamps:
      state.showTimestamps.toggle()
      return .none
      
    case .apiView:
      // TODO
      print("-----> LogCore: NOT IMPLEMENTED \(action)")
      return .none

    case .email:
      // TODO
      print("-----> LogCore: NOT IMPLEMENTED \(action)")
      return .none

    case .load:
      // TODO
      print("-----> LogCore: NOT IMPLEMENTED \(action)")
      return .none

    case .save:
      // TODO
      print("-----> LogCore: NOT IMPLEMENTED \(action)")
      return .none

    case .refresh:
      // TODO
      print("-----> LogCore: NOT IMPLEMENTED \(action)")
      return .none

    case .clear:
      // TODO
      print("-----> LogCore: NOT IMPLEMENTED \(action)")
      return .none
    }
    
  case let .filterByTextChanged(text):
    state.filterByText = text
    return .none

  case let .filterByChanged(filter):
    state.filterBy = filter
    return .none

  case let .logLevelChanged(level):
    state.logLevel = level
    return .none

  case let .fontSizeChanged(value):
    state.fontSize = value
    return .none
  }
}
  .debug("LOG ")
