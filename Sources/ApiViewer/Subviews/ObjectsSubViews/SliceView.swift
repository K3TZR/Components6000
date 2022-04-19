//
//  SliceView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct SliceView: View {
  let store: Store<ApiState, ApiAction>
  let panadapterId: PanadapterId
  let showMeters: Bool
  
  func valueColor(_ value: Float, _ low: Float, _ high: Float) -> Color {
    if value > high { return .red }
    if value < low { return .yellow }
    return .green
  }
  
  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      ForEach(viewStore.viewModel.slices) { slice in
        if slice.panadapterId == panadapterId {
          HStack(spacing: 20) {
            Text("Slice").frame(width: 100, alignment: .trailing)
            Text(String(format: "% 3d", slice.id))
            Text("\(slice.frequency)")
            Text("\(slice.mode)")
            Text("FilterLow \(slice.filterLow)")
            Text("FilterHigh \(slice.filterHigh)")
            Text("Active \(slice.active ? "Y" : "N")")
            Text("Locked \(slice.locked ? "Y" : "N")")
            Text("DAX channel \(slice.daxChannel)")
            Text("DAX clients \(slice.daxClients)")
          }
          if showMeters { MeterView(store: store, sliceId: slice.id) }
        }
      }
    }
  }
}
