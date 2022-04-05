//
//  Objects.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 2/6/22.
//

import Foundation

import Shared
import IdentifiedCollections

final public class Objects: Equatable {
  
  public static func == (lhs: Objects, rhs: Objects) -> Bool {
    // object equality since it is a "sharedInstance"
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // Dynamic Model Collections
  public var amplifiers = IdentifiedArrayOf<Amplifier>()
  public var bandSettings = IdentifiedArrayOf<BandSetting>()
  public var daxIqStreams = IdentifiedArrayOf<DaxIqStream>()
  public var daxMicAudioStreams = IdentifiedArrayOf<DaxMicAudioStream>()
  public var daxRxAudioStreams = IdentifiedArrayOf<DaxRxAudioStream>()
  public var daxTxAudioStreams = IdentifiedArrayOf<DaxTxAudioStream>()
  public var equalizers = IdentifiedArrayOf<Equalizer>()
  public var memories = IdentifiedArrayOf<Memory>()
//  public var meters = IdentifiedArrayOf<Meter>()
//  public var panadapters = IdentifiedArrayOf<Panadapter>()
  public var profiles = IdentifiedArrayOf<Profile>()
  public var remoteRxAudioStreams = IdentifiedArrayOf<RemoteRxAudioStream>()
  public var remoteTxAudioStreams = IdentifiedArrayOf<RemoteTxAudioStream>()
  public var slices = IdentifiedArrayOf<Slice>()
  public var tnfs = IdentifiedArrayOf<Tnf>()
  public var usbCables = IdentifiedArrayOf<UsbCable>()
//  public var waterfalls = IdentifiedArrayOf<Waterfall>()
  public var xvtrs = IdentifiedArrayOf<Xvtr>()
  
  // Static Models
  public internal(set) var atu: Atu!
  public internal(set) var cwx: Cwx!
  public internal(set) var gps: Gps!
  public internal(set) var interlock: Interlock!
  //  public internal(set) var netCwStream: NetCwStream!
  public internal(set) var transmit: Transmit!
  public internal(set) var wan: Wan!
  public internal(set) var waveform: Waveform!
  //  public internal(set) var wanServer: WanServer!

  
  
  
  public var meters: IdentifiedArrayOf<Meter> {
    get { objectQ.sync { _meters } }
    set { objectQ.sync(flags: .barrier) { _meters = newValue }}}

  public var panadapters: IdentifiedArrayOf<Panadapter> {
    get { objectQ.sync { _panadapters } }
    set { objectQ.sync(flags: .barrier) { _panadapters = newValue }}}

  public var waterfalls: IdentifiedArrayOf<Waterfall> {
    get { objectQ.sync { _waterfalls } }
    set { objectQ.sync(flags: .barrier) { _waterfalls = newValue }}}

  private let objectQ = DispatchQueue(label: "Objects" + ".objectQ", attributes: [.concurrent])

  private var _meters = IdentifiedArrayOf<Meter>()
  private var _panadapters = IdentifiedArrayOf<Panadapter>()
  private var _waterfalls = IdentifiedArrayOf<Waterfall>()

  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var sharedInstance = Objects()  
  private init() {}
}
