//
//  XvtrView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct XvtrView: View {
  let store: Store<ApiState, ApiAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        //        let xvtrs = viewStore.radio!.xvtrs
        
        HStack(spacing: 20) {
          Text("XVTR -> ").frame(width: 140, alignment: .leading)
          Text("XVTR NOT IMPLEMENTED")
        }
      }
    }
  }
}
