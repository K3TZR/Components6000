//
//  AppCore.swift
//  TestDiscoveryPackage/AppFeature
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture
import Dispatch
import Picker

public struct AppState: Equatable {
  public var pickerState = PickerState()
  
  public init() {}
}

public enum AppAction: Equatable {
  case pickerAction(PickerAction)
}

public struct AppEnvironment {
  public init(queue: @escaping () -> AnySchedulerOf<DispatchQueue> = { .immediate }) {

    self.queue = queue
  }
  
  var queue: () -> AnySchedulerOf<DispatchQueue> = { .main }
}

// swiftlint:disable trailing_closure
public let appReducer = Reducer<
  AppState,
  AppAction,
  AppEnvironment
>.combine(
  pickerReducer.pullback(
    state: \.pickerState,
    action: /AppAction.pickerAction,
    environment: { _ in PickerEnvironment() }
  ),
  Reducer { state, action, _ in
    switch action {
    case let .pickerAction(action):
      print("PickerAction received")
      return .none
    }
  }

)
// swiftlint:enable trailing_closure
