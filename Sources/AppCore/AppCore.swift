//
//  AppCore.swift
//  TestDiscoveryPackage/AppCore
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture
import Dispatch
import PickerCore

public struct AppState {
  public var pickerState = PickerState()
  
  public init() {}
}

public enum AppAction {
  case pickerAction(PickerAction)
}

public struct AppEnvironment {
  
  public init() {}
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
  )
)
// swiftlint:enable trailing_closure
