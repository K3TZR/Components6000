//
//  ObjectsView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/8/22.
//

import SwiftUI
import ComposableArchitecture

// ----------------------------------------------------------------------------
// MARK: - View

struct ObjectsView: View {
  let store: Store<ApiState, ApiAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      Text("----- Objects go here -----")
        .font(.system(size: viewStore.fontSize, weight: .regular, design: .monospaced))
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

struct ObjectsView_Previews: PreviewProvider {
  static var previews: some View {
    ObjectsView(
      store: Store(
        initialState: ApiState(),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
