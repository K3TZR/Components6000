//
//  ProgressCore.swift
//  Components6000/RemoteViewer  
//
//  Created by Douglas Adams on 3/23/22.
//

import Foundation
import ComposableArchitecture
import Combine

public struct ProgressState: Equatable {
  public init
  (
    heading: String = "Please Wait",
    msg: String? = nil,
    duration: Float = 1.0,
    interval: Float = 0.1
  )
  {
    self.heading = heading
    self.msg = msg
    self.duration = duration
  }
  public var heading: String
  public var msg: String?
  public var duration: Float
  public var value: Float = 0.0
}

public enum ProgressAction: Equatable {
  case startTimer
  case cancel
  case timerTicked
}

public struct ProgressEnvironment {
  public init() {}
}

public let progressReducer = Reducer<ProgressState, ProgressAction, ProgressEnvironment> { state, action, _ in
  struct TimerId: Hashable {}
  
    switch action {
    
    case .startTimer:
      return Effect.timer(id: TimerId(), every: 0.1, on: DispatchQueue.main)
        .map { _ in .timerTicked }
      
    case .cancel:
     return .cancel(id: TimerId())
      
    case .timerTicked:
      state.value += (0.1/state.duration)
      if state.value >= 1.0 {
        return Effect(value: .cancel)
      }
      return .none
      
    }
}
