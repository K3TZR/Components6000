//
//  TnfView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct TnfView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let tnfs = Array(viewStore.radio!.tnfs.values)
        
        ForEach(tnfs, id: \.id) { tnf in
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
