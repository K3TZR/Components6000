//
//  SwiftUIView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

import Radio

struct AmplifierView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(store.actionless) { viewStore in
      
      ForEach(viewStore.objects.amplifiers) { amplifier in
        HStack(spacing: 20) {
          Text("Amplifier").frame(width: 100, alignment: .trailing)
          Text(amplifier.id.hex)
          Text(amplifier.model)
          Text(amplifier.ip)
          Text("Port \(amplifier.port)")
          Text(amplifier.state)
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

import Radio
import TcpCommands
import UdpStreams
import Shared

struct AmplifierView_Previews: PreviewProvider {
  static var previews: some View {
    AmplifierView(
      store: Store(
        initialState: ApiState(
          radio: Radio(Packet(),
                       connectionType: .gui,
                       command: Tcp(),
                       stream: Udp())
        ),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
