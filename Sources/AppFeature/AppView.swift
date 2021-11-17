//
//  AppView.swift
//  TestDiscoveryPackage/AppView
//
//  Created by Douglas Adams on 10/19/21.
//

import SwiftUI
import ComposableArchitecture
import Picker

public struct AppView: View {
  let store: Store<AppState, AppAction>
  
  public var body: some View {
//    WithViewStore(self.store) { viewStore in
//      if viewStore.selectedView == .picker {
        PickerView(
          store: store.scope(
            state: \.pickerState,
            action: AppAction.pickerAction)
        ).frame(width: 600, height: 400)
//          .toolbar {
//            Button("Favorite") { viewStore.send(.selectedViewChanged(.favorite)) }
//          }

        
//      } else {
//        FavoriteListView(
//          store: store.scope(
//            state: \.pickerState,
//            action: AppAction.pickerAction)
//        )
//          .toolbar {
//            Button("Picker") { viewStore.send(.selectedViewChanged(.picker)) }
//          }
//
//      }
//    }
  }
}

struct Appiew_Previews: PreviewProvider {
  static var previews: some View {
    let appView = AppView(
      store: Store(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnvironment()
      )
    )
    return appView
  }
}
