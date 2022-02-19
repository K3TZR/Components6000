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
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let tnfs = Array(Objects.sharedInstance.tnfs)

        ForEach(tnfs) { tnf in
          HStack(spacing: 20) {
            Text("Tnf").frame(width: 100, alignment: .trailing)
            Text(tnf.id.hex)
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
