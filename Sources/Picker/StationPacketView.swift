//
//  SwiftUIView.swift
//  Components6000/Picker
//
//  Created by Douglas Adams on 11/22/21.
//

import SwiftUI
import ComposableArchitecture

import Shared

// ----------------------------------------------------------------------------
// MARK: - View(s)

struct StationPacketView: View {
  let store: Store<Packet, StationPacketAction>

  @State var isSelected = false

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 0) {
        Button(action: { viewStore.send(.defaultButton) }) {
          Image(systemName: viewStore.isDefault ? "checkmark.square" : "square")
        }
        .frame(width: 95, alignment: .center)
        .buttonStyle(PlainButtonStyle())


        Group {
          Text(viewStore.source.rawValue)
          Text(viewStore.nickname)
          Text(viewStore.status)
          Text(viewStore.guiClientStations)
        }.onTapGesture { isSelected.toggle() ; viewStore.send(.selection(isSelected))}
        .font(.title3)
        .frame(width: 140, alignment: .leading)
      }
      .foregroundColor(isSelected ? Color(.red) : Color(.white))
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct StationPacketView_Previews: PreviewProvider {
    static var previews: some View {
      StationPacketView(store: Store(
        initialState: testPacket1(),
        reducer: stationPacketReducer,
        environment: StationPacketEnvironment() )
      )
    }
}
