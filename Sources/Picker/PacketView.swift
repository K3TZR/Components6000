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
        Button(action: { viewStore.send(.buttonTapped(.defaultBox)) }) {
          Image(systemName: viewStore.isDefault ? "checkmark.square" : "square")
        }
        .frame(width: 95, alignment: .center)
        .buttonStyle(PlainButtonStyle())
        
        
        Group {
          Text(viewStore.isWan ? "Smartlink" : "Local")
          Text(viewStore.nickname)
          Text(viewStore.status)
          Text(viewStore.guiClientStations)
        }.onTapGesture {
          viewStore.send(.packetTapped)
        }
        .font(.title3)
        .frame(width: 140, alignment: .leading)
      }
      .foregroundColor(viewStore.isSelected ? Color(.red) : Color(.white))
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

