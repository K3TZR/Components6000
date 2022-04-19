//
//  TnfView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

import Radio

struct TnfView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      if viewStore.radio != nil {
//        let tnfs = Array(viewStore.viewModel.tnfs)

        ForEach(Array(viewStore.viewModel.tnfs)) { tnf in
          HStack(spacing: 20) {
            Text("Tnf").frame(width: 100, alignment: .trailing)
            Text(String(format: "%d", tnf.id))
            Text("Frequency \(tnf.frequency)")
            Text("Width \(tnf.width)")
            Text("Depth \(tnf.depth)")
            Text("Permanent \(tnf.permanent ? "Y" : "N")")
          }
        }
      }
    }
  }
}
