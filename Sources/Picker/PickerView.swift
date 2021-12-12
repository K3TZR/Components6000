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

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct PickerView: View {
  let store: Store<PickerState, PickerAction>
  
  public init(store: Store<PickerState, PickerAction>) {
    self.store = store
  }

  public var body: some View {
    
    WithViewStore(store) { viewStore in
      VStack(alignment: .leading) {
        PickerHeader(pickType: viewStore.pickType)
        Divider()
        if viewStore.discovery.packets.collection.count == 0 {
          Spacer()
          HStack {
            Spacer()
            Text("----------  NO  \(viewStore.pickType.rawValue)S  FOUND  ----------").foregroundColor(.red)
            Spacer()
          }
          Spacer()
        } else {
          List {
          ForEachStore(
            self.store.scope(state: \.discovery.packets.collection, action: PickerAction.packet(index:action:))
            ) { packetStore in
              PacketView(store: packetStore)
            }
          }
        }
        Divider()
        PickerFooter(store: store)
      }
      .frame(minWidth: 650, minHeight: 200, idealHeight: 300, maxHeight: 400)
      .onAppear {
        viewStore.send(.onAppear)
      }
//      .onDisappear {
//        viewStore.send(.onDisappear)
//      }
    }
  }
}

struct PickerHeader: View {
  let pickType: PickType
  
  var body: some View {
    VStack {
      Text("Select a \(pickType.rawValue)")
        .font(.title)
        .padding(.bottom, 10)
      
      HStack(spacing: 0) {
        Group {
          Text("Default")
        }
        .font(.title2)
        .frame(width: 95, alignment: .leading)
        
        Group {
          Text("Type")
          Text("Name")
          Text("Status")
          Text("Station(s)")
        }
        .frame(width: 140, alignment: .leading)
      }
    }
    .font(.title2)
    .padding(.vertical, 10)
    .padding(.horizontal)
  }
}

struct PickerFooter: View {
  let store: Store<PickerState, PickerAction>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      
      HStack(){
        Button("Test") {viewStore.send(.buttonTapped(.test))}
        .disabled(viewStore.selectedPacket == nil)
        Circle()
          .fill(viewStore.testStatus ? Color.green : Color.red)
          .frame(width: 20, height: 20)
        
        Spacer()
        Button("Cancel") {viewStore.send(.buttonTapped(.cancel)) }
        .keyboardShortcut(.cancelAction)
        
        Spacer()
        Button("Connect") {viewStore.send(.buttonTapped(.connect))}
        .keyboardShortcut(.defaultAction)
        .disabled(viewStore.selectedPacket == nil)
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct PickerView_Previews: PreviewProvider {
  static var previews: some View {

    PickerView(
      store: Store(
        initialState: PickerState(testStatus: true),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
    PickerView(
      store: Store(
        initialState: PickerState(pickType: .radio, testStatus: true),
        reducer: pickerReducer,
        environment: PickerEnvironment()
      )
    )
  }
}

struct PickerHeader_Previews: PreviewProvider {
  static var previews: some View {
    PickerHeader(pickType: .radio)
  }
}

struct PickerFooter_Previews: PreviewProvider {
  static var previews: some View {

    PickerFooter(store: Store(
      initialState: PickerState(pickType: .radio, testStatus: true),
      reducer: pickerReducer,
      environment: PickerEnvironment() )
    )
  }
}

// ----------------------------------------------------------------------------
// MARK: - Test data

func emptyTestPackets() -> [Packet] {
  return [Packet]()
}

func testPackets() -> [Packet] {
  var packets = [Packet]()
  
  packets.append(testPacket1())
  packets.append(testPacket2())

  return packets
}

func testPacket1() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6500"
  packet.status = "Available"
  packet.serial = "1234-5678-9012-3456"
  packet.publicIp = "10.0.1.200"
  packet.guiClientHandles = "1,2"
  packet.guiClientPrograms = "SmartSDR-Windows,SmartSDR-iOS"
  packet.guiClientStations = "Windows,iPad"
  packet.guiClientHosts = ""
  packet.guiClientIps = "192.168.1.200,192.168.1.201"

  return packet
}

func testPacket2() -> Packet {
  var packet = Packet()
  packet.nickname = "Dougs 6700"
  packet.status = "Available"
  packet.serial = "5678-9012-3456-7890"
  packet.publicIp = "40.0.2.278"
  packet.guiClientHandles = ""
  packet.guiClientPrograms = ""
  packet.guiClientStations = ""
  packet.guiClientHosts = ""
  packet.guiClientIps = ""


  return packet
}

