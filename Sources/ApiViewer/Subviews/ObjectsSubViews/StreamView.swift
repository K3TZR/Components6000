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
    WithViewStore(store.actionless) { viewStore in
      
      VStack(alignment: .leading) {
        ForEach(viewStore.objects.remoteRxAudioStreams) { stream in
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
        ForEach(viewStore.objects.remoteTxAudioStreams) { stream in
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
        ForEach(viewStore.objects.daxMicAudioStreams) { stream in
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
        ForEach(viewStore.objects.daxRxAudioStreams) { stream in
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
        ForEach(viewStore.objects.daxTxAudioStreams) { stream in
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
        ForEach(viewStore.objects.daxIqStreams) { stream in
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
    }
  }
}
