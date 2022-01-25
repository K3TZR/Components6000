//
//  WaveformView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

struct WaveformView: View {
  let store: Store<ApiState, ApiAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        //        let waveforms = viewStore.radio!.waveforms
        
        HStack(spacing: 20) {
          Text("WAVEFORM -> ").frame(width: 140, alignment: .leading)
          Text("WAVEFORM NOT IMPLEMENTED")
        }
      }
    }
  }
}
