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
    title: String? = nil,
    duration: Float = 1.0
  )
  {
    self.title = title
    self.duration = duration
  }
  public var title: String?
  public var duration: Float
  public var progressValue: Float = 0.0
}

public enum ProgressAction: Equatable {
  case startTimer
  case cancel
  case timerTicked
}

public struct ProgressEnvironment {}

public let progressReducer = Reducer<ProgressState, ProgressAction, ProgressEnvironment> { state, action, _ in
  struct TimerId: Hashable {}
  
    switch action {
    
    case .startTimer:
      return Effect.timer(id: TimerId(), every: 0.5, on: DispatchQueue.main)
        .map { _ in .timerTicked }
      
    case .cancel:
     return .cancel(id: TimerId())
      
    case .timerTicked:
      state.progressValue += (0.5/state.duration)
      if state.progressValue >= 1.0 {
        return Effect(value: .cancel)
      }
      return .none
      
    }
}
