//
//  Objects.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 2/6/22.
//

import Foundation

import Shared

final public class Objects: ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  // Dynamic Model Collections
  @Published public var amplifiers = [AmplifierId: Amplifier]()
  @Published public var bandSettings = [BandId: BandSetting]()
  @Published public var daxIqStreams = [DaxIqStreamId: DaxIqStream]()
  @Published public var daxMicAudioStreams = [DaxMicStreamId: DaxMicAudioStream]()
  @Published public var daxRxAudioStreams = [DaxRxStreamId: DaxRxAudioStream]()
  @Published public var daxTxAudioStreams = [DaxTxStreamId: DaxTxAudioStream]()
  @Published public var equalizers = [Equalizer.EqType: Equalizer]()
  @Published public var memories = [MemoryId: Memory]()
  @Published public var meters = [MeterId: Meter]()
  @Published public var panadapters = [PanadapterStreamId: Panadapter]()
  @Published public var profiles = [ProfileId: Profile]()
  @Published public var remoteRxAudioStreams = [RemoteRxStreamId: RemoteRxAudioStream]()
  @Published public var remoteTxAudioStreams = [RemoteTxStreamId: RemoteTxAudioStream]()
  @Published public var slices = [SliceId: Slice]()
  @Published public var tnfs = [TnfId: Tnf]()
  @Published public var usbCables = [UsbCableId: UsbCable]()
  @Published public var waterfalls = [WaterfallStreamId: Waterfall]()
  @Published public var xvtrs = [XvtrId: Xvtr]()
  
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
