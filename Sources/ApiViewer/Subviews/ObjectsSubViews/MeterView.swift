//
//  MeterView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct MeterView: View {
  let store: Store<ApiState, ApiAction>
  let sliceId: ObjectId?
  
  var body: some View {
    
    WithViewStore(store) { viewStore in
      VStack(alignment: .leading) {
        ForEachStore(
          store.scope(
            state: \.objects.meters,
            action: ApiAction.meter(id:action:)
          ),
          content: { MeterRowView(store: $0.actionless, sliceId: sliceId) }
        )
      }
      .foregroundColor(.secondary)
      .onAppear() { viewStore.send(.startMetersSubscription) }
      .onDisappear() { viewStore.send(.stopMetersSubscription) }
    }
  }
}

struct MeterRowView: View {
  let store: Store<Meter, Never>
  let sliceId: SliceId?
  
  func valueColor(_ value: Float, _ low: Float, _ high: Float) -> Color {
    if value > high { return .red }
    if value < low { return .yellow }
    return .green
  }
  
  var body: some View {
    WithViewStore(store) { viewStore in
      if sliceId == nil && viewStore.source != "slc" || sliceId != nil && viewStore.source == "slc" && UInt16(viewStore.group) == sliceId {
        HStack(spacing: 0) {
          Text("Meter").padding(.leading, sliceId == nil ? 20: 40)
          Text(String(format: "% 3d", viewStore.id)).frame(width: 50, alignment: .leading)
          Text(viewStore.group).frame(width: 30, alignment: .trailing).padding(.trailing)
          Text(viewStore.name).frame(width: 110, alignment: .leading)
          Text(String(format: "%-4.2f", viewStore.low)).frame(width: 75, alignment: .trailing)
          Text(String(format: "%-4.2f", viewStore.value))
            .foregroundColor(valueColor(viewStore.value, viewStore.low, viewStore.high))
            .frame(width: 75, alignment: .trailing)
          Text(String(format: "%-4.2f", viewStore.high)).frame(width: 75, alignment: .trailing)
          Text(viewStore.units).frame(width: 50, alignment: .leading)
          Text(String(format: "%02d", viewStore.fps) + " fps").frame(width: 75, alignment: .leading).padding(.trailing)
          Text(viewStore.desc)
            .frame(width: 1000, alignment: .leading)
        }
      }
    }
  }
}
