//
//  PickerView.swift
//  TestDiscoveryPackage/Picker
//
//  Created by Douglas Adams on 11/13/21.
//

import SwiftUI
import Combine
import ComposableArchitecture
import Discovery
import Shared

public struct PickerView: View {
  let store: Store<PickerState, PickerAction>
  
  public init(store: Store<PickerState, PickerAction>) {
    self.store = store
  }

  @State var pickerSelection: UUID?
  
  public var body: some View {
    
    WithViewStore(self.store) { viewStore in
      VStack(alignment: .leading) {
        PickerHeader()
        Divider()
        if viewStore.packets.count == 0 {
          Spacer()
          HStack {
            Spacer()
            Text("----- No packets -----")
            Spacer()
          }
          Spacer()
        } else {
          List {
            ForEachStore(
              self.store.scope(state: \.packets, action: PickerAction.packet(index:action:))
            ) { packetStore in
              PacketView(store: packetStore)
            }
          }
        }
        Divider()
        PickerFooter(viewStore: viewStore)
      }
      .frame(minWidth: 650, minHeight: 200, idealHeight: 300, maxHeight: 400)
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }
}

struct PickerHeader: View {
  var body: some View {
    HStack(spacing: 0) {
      Group {
        Text("Default")
        Text("Type")
      }.frame(width: 95, alignment: .leading)
      
      Group {
        Text("Name")
        Text("Status")
        Text("Station(s)")
      }.frame(width: 140, alignment: .leading)
    }
    .padding(.vertical, 10)
    .padding(.horizontal)
    .font(.title)
  }
}

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

struct PickerFooter: View {
  let viewStore: ViewStore<PickerState, PickerAction>

  var body: some View {
    HStack(){
      Button("Test") {viewStore.send(.testButtonTapped)}
        .disabled(viewStore.selectedPacket == nil)
      Circle()
        .fill(viewStore.testStatus ? Color.green : Color.red)
          .frame(width: 20, height: 20)

      Spacer()
      Button("Cancel") {viewStore.send(.cancelButtonTapped)}
        .keyboardShortcut(.cancelAction)
      
      Spacer()
      Button("Connect") {viewStore.send(.connectButtonTapped)}
        .keyboardShortcut(.defaultAction)
        .disabled(viewStore.selectedPacket == nil)
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 10)
  }
}

struct PickerView_Previews: PreviewProvider {
  
  static var previews: some View {

    PickerView(
      store: Store(
        initialState: PickerState(packets: testPackets(),
                                  testStatus: true),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
    PickerView(
      store: Store(
        initialState: PickerState(packets: emptyTestPackets(),
                                  testStatus: true),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
  }
}


private func emptyTestPackets() -> [Packet] {
  return [Packet]()
}

private func testPackets() -> [Packet] {
  var packets = [Packet]()
  var packet: Packet
  
  packet = Packet()
  packet.nickname = "Dougs 6500"
  packet.status = "Available"
  packet.serialNumber = "1234-5678-9012-3456"
  packet.publicIp = "10.0.1.200"
  packet.guiClientHandles = "1,2"
  packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
  packet.guiClientStations = "Windows,iPad"
  packet.guiClientHosts = ""
  packet.guiClientIps = "192.168.1.200,192.168.1.201"
  packet.isWan = false
  packets.append(packet)

  packet = Packet()
  packet.nickname = "Dougs 6700"
  packet.status = "Available"
  packet.serialNumber = "5678-9012-3456-7890"
  packet.publicIp = "40.0.2.278"
  packet.guiClientHandles = ""
  packet.guiClientPrograms = ""
  packet.guiClientStations = ""
  packet.guiClientHosts = ""
  packet.guiClientIps = ""
  packet.isWan = true
  packets.append(packet)

  return packets
}

