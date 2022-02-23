//
//  XvtrView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct XvtrView: View {
  let store: Store<ApiState, ApiAction>

  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      if viewStore.radio != nil {
        
        HStack(spacing: 20) {
          Text("XVTR -> ").frame(width: 140, alignment: .leading)
          Text("XVTR NOT IMPLEMENTED")
        }
      }
    }
  }
}
