//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 11/22/21.
//

import SwiftUI
import ComposableArchitecture
import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

struct PacketView: View {
  let store: Store<Packet, PacketAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 0) {
        Button(action: { viewStore.send(.checkboxTapped) }) {
          Image(systemName: viewStore.isDefault ? "checkmark.square" : "square")
        }
        .frame(width: 95, alignment: .center)
        .buttonStyle(PlainButtonStyle())
        
        Text(viewStore.isWan ? "Smartlink" : "Local").frame(width: 95, alignment: .leading)
        
        Group {
          Text(viewStore.nickname)
          Text(viewStore.status)
          Text(viewStore.guiClientStations)
        }.frame(width: 140, alignment: .leading)
      }
      .foregroundColor(viewStore.isDefault ? .red : nil)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct PacketView_Previews: PreviewProvider {
    static var previews: some View {
      PacketView(store: Store(
        initialState: testPacket1(),
        reducer: packetReducer,
        environment: PacketEnvironment() )
      )
    }
}

