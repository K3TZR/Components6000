//
//  PickerView.swift
//  TestDiscoveryPackage/PickerView
//
//  Created by Douglas Adams on 11/13/21.
//

import SwiftUI
import Combine
import ComposableArchitecture
import PickerCore
import Discovery

public struct PickerListView: View {
  let store: Store<PickerState, PickerAction>
  
  public init(store: Store<PickerState, PickerAction>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      ScrollView {
        LazyVStack {
          ForEach(viewStore.packets) { packet in
            PickerView(store: store, packet: packet)
              .padding([.leading, .trailing, .bottom])
          }
        }
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }
}

struct PickerView: View {
  let store: Store<PickerState, PickerAction>
  let packet: Packet
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        HStack {
          Text(packet.nickname)
            .font(.title)
          Spacer()
          HStack {
            Text("Default")
            Button(
              action: { viewStore.send(.defaultButtonTapped(packet)) },
              label: {
                if viewStore.defaultPacket == packet {
                  Image(systemName: "checkmark.square")
                } else {
                  Image(systemName: "square")
                }
              })
          }
        }
        VStack(alignment: .leading) {
          Text(packet.status)
          Text(packet.serialNumber)
          Text(packet.publicIp)
          Text(packet.guiClientStations)
        }
      }
      .padding()
      .foregroundColor(Color(.white))
      .background(Color(.gray))
      .cornerRadius(8.0)
    }
    .debug()
  }
}

struct PickerListView_Previews: PreviewProvider {
  static var previews: some View {
    PickerListView(
      store: Store(
        initialState: PickerState(),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
  }
}

