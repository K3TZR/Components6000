//
//  PickerCore.swift
//  
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture
import Dispatch

public struct PickerState: Equatable {
  public var isDefault = false

  public init() {}
}

public enum PickerAction: Equatable {
  case defaultButtonTapped
}

public struct PickerEnvironment {
  public var mainQueue: AnySchedulerOf<DispatchQueue>

  public init( mainQueue: AnySchedulerOf<DispatchQueue> ) {
    self.mainQueue = mainQueue
  }
}

public let pickerReducer = Reducer<PickerState, PickerAction, PickerEnvironment>
{ state, action, environment in
  switch action {
    
  case .defaultButtonTapped:
    state.isDefault.toggle()
    return .none
  }
}
