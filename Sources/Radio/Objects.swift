//
//  Objects.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 2/6/22.
//

import Foundation

import Shared
import IdentifiedCollections

final public class Objects: ObservableObject, Equatable {
  
  public static func == (lhs: Objects, rhs: Objects) -> Bool {
    // object equality since it is a "sharedInstance"
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  // Dynamic Model Collections
  @Published public var amplifiers = IdentifiedArrayOf<Amplifier>()
  @Published public var bandSettings = IdentifiedArrayOf<BandSetting>()
  @Published public var daxIqStreams = IdentifiedArrayOf<DaxIqStream>()
  @Published public var daxMicAudioStreams = IdentifiedArrayOf<DaxMicAudioStream>()
  @Published public var daxRxAudioStreams = IdentifiedArrayOf<DaxRxAudioStream>()
  @Published public var daxTxAudioStreams = IdentifiedArrayOf<DaxTxAudioStream>()
  @Published public var equalizers = IdentifiedArrayOf<Equalizer>()
  @Published public var memories = IdentifiedArrayOf<Memory>()
  @Published public var meters = IdentifiedArrayOf<Meter>()
  @Published public var panadapters = IdentifiedArrayOf<Panadapter>()
  @Published public var profiles = IdentifiedArrayOf<Profile>()
  @Published public var remoteRxAudioStreams = IdentifiedArrayOf<RemoteRxAudioStream>()
  @Published public var remoteTxAudioStreams = IdentifiedArrayOf<RemoteTxAudioStream>()
  @Published public var slices = IdentifiedArrayOf<Slice>()
  @Published public var tnfs = IdentifiedArrayOf<Tnf>()
  @Published public var usbCables = IdentifiedArrayOf<UsbCable>()
  @Published public var waterfalls = IdentifiedArrayOf<Waterfall>()
  @Published public var xvtrs = IdentifiedArrayOf<Xvtr>()
  
  // Static Models
  @Published public internal(set) var atu: Atu!
  @Published public internal(set) var cwx: Cwx!
  @Published public internal(set) var gps: Gps!
  @Published public internal(set) var interlock: Interlock!
  //  @Published public internal(set) var netCwStream: NetCwStream!
  @Published public internal(set) var transmit: Transmit!
  @Published public internal(set) var wan: Wan!
  @Published public internal(set) var waveform: Waveform!
  //  @Published public internal(set) var wanServer: WanServer!

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var sharedInstance = Objects()  
  private init() {}
}
