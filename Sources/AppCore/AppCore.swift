//
//  File.swift
//  
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture
import Dispatch
import PickerCore
import FavoriteCore

public enum AppState: Equatable {
  case picker(PickerState)
  case favorite(FavoriteState)

  public init() { self = .picker(.init()) }
}

public enum AppAction: Equatable {
  case picker(PickerAction)
  case favorite(FavoriteAction)
}

public struct AppEnvironment {
  public var mainQueue: AnySchedulerOf<DispatchQueue>

  public init(
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.mainQueue = mainQueue
  }
}

public let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  pickerReducer.pullback(
    state: /AppState.picker,
    action: /AppAction.picker,
    environment: {
      PickerEnvironment(
        mainQueue: $0.mainQueue
      )
    }
  ),
  favoriteReducer.pullback(
    state: /AppState.favorite,
    action: /AppAction.favorite,
    environment: { _ in FavoriteEnvironment() }
  ),
  Reducer { state, action, _ in
    switch action {
    case .picker(let action):
      return .none

    case .favorite(let action):
      return .none
    }
  }
)
.debug()
