//
//  PanadapterView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct PanadapterView: View {
  let store: Store<ApiState, ApiAction>
  let handle: Handle
  let showMeters: Bool
  
  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      ForEach(viewStore.objects.panadapters) { panadapter in
        if panadapter.clientHandle == handle {
          HStack(spacing: 20) {
            Text("Panadapter").frame(width: 100, alignment: .trailing)
            Text(panadapter.id.hex)
            Text("Center \(panadapter.center)")
            Text("Bandwidth \(panadapter.bandwidth)")
          }
          WaterfallView(store: store, panadapterId: panadapter.id)
          SliceView(store: store, panadapterId: panadapter.id, showMeters: showMeters)
        }
      }
    }
  }
}
