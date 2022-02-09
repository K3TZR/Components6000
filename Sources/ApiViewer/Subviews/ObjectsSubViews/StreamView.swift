//
//  StreamView.swift
//  Components6000/ApiViewer/Subviews/ObjectsSubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import SwiftUI
import ComposableArchitecture

import Radio
import Shared

struct StreamView: View {
  let store: Store<ApiState, ApiAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.radio != nil {
        let remoteRx = Array(Objects.sharedInstance.remoteRxAudioStreams.values)
        let remoteTx = Array(Objects.sharedInstance.remoteTxAudioStreams.values)
        let daxMic = Array(Objects.sharedInstance.daxMicAudioStreams.values)
        let daxRx = Array(Objects.sharedInstance.daxRxAudioStreams.values)
        let daxTx = Array(Objects.sharedInstance.daxTxAudioStreams.values)
        let daxIq = Array(Objects.sharedInstance.daxIqStreams.values)

        VStack(alignment: .leading) {
          ForEach(remoteRx) { stream in
            if viewStore.radio!.connectionHandle == stream.clientHandle {
              HStack(spacing: 20) {
                Text("RemoteRxAudioStream")
                Text(stream.id.hex)
                Text("Handle \(stream.clientHandle.hex)")
                Text("Compression \(stream.compression)")
                Text("Ip \(stream.ip)")
              }
              .foregroundColor(.red)
            }
          }
          ForEach(remoteTx) { stream in
            if viewStore.radio!.connectionHandle == stream.clientHandle {
              HStack(spacing: 20) {
                Text("RemoteTxAudioStream")
                Text(stream.id.hex)
                Text("Handle \(stream.clientHandle.hex)")
                Text("Compression \(stream.compression)")
              }
              .foregroundColor(.orange)
            }
          }
          ForEach(daxMic) { stream in
            if viewStore.radio!.connectionHandle == stream.clientHandle {
              HStack(spacing: 20) {
                Text("DaxMicAudioStream")
                Text(stream.id.hex)
                Text("Handle \(stream.clientHandle.hex)")
                Text("Ip \(stream.ip)")
              }
              .foregroundColor(.yellow)
            }
          }
          ForEach(daxRx) { stream in
            if viewStore.radio!.connectionHandle == stream.clientHandle {
              HStack(spacing: 20) {
                Text("DaxRxAudioStream")
                Text(stream.id.hex)
                Text("Handle \(stream.clientHandle.hex)")
                Text("Channel \(stream.daxChannel)")
                Text("Ip \(stream.ip)")
              }
              .foregroundColor(.green)
            }
          }
          ForEach(daxTx) { stream in
            if viewStore.radio!.connectionHandle == stream.clientHandle {
              HStack(spacing: 20) {
                Text("DaxTxAudioStream")
                Text("Id=\(stream.id.hex)")
                Text("ClientHandle=\(stream.clientHandle.hex)")
                Text("Transmit=\(stream.isTransmitChannel ? "Y" : "N")")
              }
              .foregroundColor(.blue)
            }
          }
          ForEach(daxIq) { stream in
            if viewStore.radio!.connectionHandle == stream.clientHandle {
              HStack(spacing: 20) {
                Text("DaxIqStream")
                Text(stream.id.hex)
                Text("Handle=\(stream.clientHandle.hex)")
                Text("Channel \(stream.channel)")
                Text("Ip \(stream.ip)")
                Text("Pan \(stream.pan.hex)")
              }
              .foregroundColor(.purple)
            }
          }
        }
//        .padding(.leading, 20)
      }
    }
  }
}
