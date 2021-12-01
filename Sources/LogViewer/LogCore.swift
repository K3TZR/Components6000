//
//  LogCore.swift
//  TestDiscoveryPackage/Log
//
//  Created by Douglas Adams on 11/30/21.
//

import ComposableArchitecture

public enum LogButton: Equatable {
  case showTimestamps
  case apiTester
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
  
  public init() {}
}

public enum LogAction: Equatable {
  case buttonTapped(LogButton)
  case filterByTextChanged(String)
  case filterByChanged(String)
  case logLevelChanged(String)
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
      
    case .apiTester:
      print("LogCore: button .apiTester")
      return .none

    case .email:
      print("LogCore: button .email")
      return .none

    case .load:
      print("LogCore: button .load")
      return .none

    case .save:
      print("LogCore: button .save")
      return .none

    case .refresh:
      print("LogCore: button .refresh")
      return .none

    case .clear:
      print("LogCore: button .clear")
      return .none
    }
    
  case let .filterByTextChanged(text):
    state.filterByText = text
    return .none

  case let .filterByChanged(string):
    state.filterBy = LogFilter(rawValue: string) ?? .none
    return .none

  case let .logLevelChanged(string):
    state.logLevel = LogLevel(rawValue: string) ?? .debug
    return .none

  case let .fontSizeChanged(value):
    state.fontSize = value
    return .none
  }
  
}
  .debug()
