//
//  PacketView.swift
//  Components6000/Picker
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

  @State var isSelected = false

  var body: some View {
    WithViewStore(self.store) { viewStore in
      ZStack {
        HStack(spacing: 0) {
          Button(action: { viewStore.send(.defaultButton) }) {
            Image(systemName: viewStore.isDefault ? "checkmark.square" : "square")
          }
          .buttonStyle(PlainButtonStyle())
          .labelsHidden()
          .frame(width: 95, alignment: .leading)

          Group {
            Text(viewStore.source.rawValue)
            Text(viewStore.nickname)
            Text(viewStore.status)
            Text(viewStore.guiClientStations)
          }
          .onTapGesture { isSelected.toggle() ; viewStore.send(.selection(isSelected))}
          .font(.title3)
          .frame(width: 140, alignment: .leading)
        }
        Rectangle().fill(isSelected ? .gray : .clear).frame(width: 700, height: 20).opacity(0.2)
      }
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
    .frame(minWidth: 700)
    .padding(.horizontal)
  }
}

