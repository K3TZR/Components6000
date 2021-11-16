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
      VStack(alignment: .leading, spacing: 10) {
        PickerHeader()
        Divider()
        PickerList(viewStore: viewStore)
        Divider()
        PickerFooter(viewStore: viewStore)
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }
}

struct PickerHeader: View {
  var body: some View {
    HStack(spacing: 50) {
      Text("Default")
      Text("Type")
      Text("Name")
      Text("Status")
      Text("Station(s)")
    }
//    .frame(width: 100, alignment: .leading)
    .padding(.horizontal, 10)
    .font(.title)
  }
}

struct PickerList: View {
  let viewStore: ViewStore<PickerState, PickerAction>
  
  @State var pickerSelection: UUID?
  @State var isDefault = false
  
  let stdColor = Color(.controlTextColor)
  var body: some View {
    
    List(viewStore.packets, selection: $pickerSelection) { packet in
        PacketView(packet: packet)
    }.frame(alignment: .leading)
  }
  //      .foregroundColor( packet.isDefault ? .red : stdColor )
}

struct PacketView: View {
  let packet: Packet

  @State var isDefault = false

  let stdColor = Color(.controlTextColor)
  var body: some View {
    HStack {
      Toggle("", isOn: $isDefault).frame(width: 100, alignment: .leading)
      Text(packet.isWan ? "Smartlink" : "Local").frame(width: 100, alignment: .leading)
      Text(packet.nickname).frame(width: 100, alignment: .leading)
      Text(packet.status).frame(width: 100, alignment: .leading)
      Text(packet.guiClientStations).frame(width: 100, alignment: .leading)
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

struct PickerListView_Previews: PreviewProvider {
  
  static var previews: some View {

    PickerListView(
      store: Store(
        initialState: PickerState(packets: testPackets(),
                                  testStatus: true),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
  }
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

