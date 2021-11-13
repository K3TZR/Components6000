//
//  FavoriteCore.swift
//  
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture

public struct FavoriteState: Equatable {
  public var isDefault = false

  public init() {}
}

public enum FavoriteAction: Equatable {
  case pickerButtonTapped
  case defaultButtonTapped
}

public struct FavoriteEnvironment {
  public init() {}
}

public let favoriteReducer = Reducer<FavoriteState, FavoriteAction, FavoriteEnvironment>
{ state, action, _ in
  switch action {
    
  case .defaultButtonTapped:
    state.isDefault.toggle()
    return .none
    
  case .pickerButtonTapped:
    print("Needs to return to picker")
    return .none
  }
}

