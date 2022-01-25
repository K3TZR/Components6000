//
//  SwiftUIView.swift
//  Components6000/ApiViewer
//
//  Created by Douglas Adams on 1/24/22.
//

import SwiftUI
import ComposableArchitecture

struct AmplifierView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let amplifiers = Array(viewStore.radio!.amplifiers.values)
        
        ForEach(amplifiers, id: \.id) { amplifier in
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
          domain: "net.k3tzr",
          appName: "Api6000",
          radio: Radio(Packet(),
                       connectionType: .gui,
                       command: TcpCommand(),
                       stream: UdpStream())
        ),
        reducer: apiReducer,
        environment: ApiEnvironment()
      )
    )
      .frame(minWidth: 975)
  }
}
