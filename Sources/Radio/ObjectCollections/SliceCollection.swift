//
//  SliceCollection.swift
//  
//
//  Created by Douglas Adams on 4/17/22.
//

import Foundation
import IdentifiedCollections

import Shared

@globalActor
public actor SliceCollection {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton

  public static let shared = SliceCollection()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var slices: IdentifiedArrayOf<Slice> = []
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  enum SliceTokens : String {
    case active
    case agcMode                    = "agc_mode"
    case agcOffLevel                = "agc_off_level"
    case agcThreshold               = "agc_threshold"
    case anfEnabled                 = "anf"
    case anfLevel                   = "anf_level"
    case apfEnabled                 = "apf"
    case apfLevel                   = "apf_level"
    case audioGain                  = "audio_gain"
    case audioLevel                 = "audio_level"
    case audioMute                  = "audio_mute"
    case audioPan                   = "audio_pan"
    case clientHandle               = "client_handle"
    case daxChannel                 = "dax"
    case daxClients                 = "dax_clients"
    case daxTxEnabled               = "dax_tx"
    case detached
    case dfmPreDeEmphasisEnabled    = "dfm_pre_de_emphasis"
    case digitalLowerOffset         = "digl_offset"
    case digitalUpperOffset         = "digu_offset"
    case diversityEnabled           = "diversity"
    case diversityChild             = "diversity_child"
    case diversityIndex             = "diversity_index"
    case diversityParent            = "diversity_parent"
    case filterHigh                 = "filter_hi"
    case filterLow                  = "filter_lo"
    case fmDeviation                = "fm_deviation"
    case fmRepeaterOffset           = "fm_repeater_offset_freq"
    case fmToneBurstEnabled         = "fm_tone_burst"
    case fmToneMode                 = "fm_tone_mode"
    case fmToneFreq                 = "fm_tone_value"
    case frequency                  = "rf_frequency"
    case ghost
    case inUse                      = "in_use"
    case locked                     = "lock"
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case mode
    case modeList                   = "mode_list"
    case nbEnabled                  = "nb"
    case nbLevel                    = "nb_level"
    case nrEnabled                  = "nr"
    case nrLevel                    = "nr_level"
    case nr2
    case owner
    case panadapterId               = "pan"
    case playbackEnabled            = "play"
    case postDemodBypassEnabled     = "post_demod_bypass"
    case postDemodHigh              = "post_demod_high"
    case postDemodLow               = "post_demod_low"
    case qskEnabled                 = "qsk"
    case recordEnabled              = "record"
    case recordTime                 = "record_time"
    case repeaterOffsetDirection    = "repeater_offset_dir"
    case rfGain                     = "rfgain"
    case ritEnabled                 = "rit_on"
    case ritOffset                  = "rit_freq"
    case rttyMark                   = "rtty_mark"
    case rttyShift                  = "rtty_shift"
    case rxAnt                      = "rxant"
    case rxAntList                  = "ant_list"
    case sampleRate                 = "sample_rate"
    case sliceLetter                = "index_letter"
    case squelchEnabled             = "squelch"
    case squelchLevel               = "squelch_level"
    case step
    case stepList                   = "step_list"
    case txEnabled                  = "tx"
    case txAnt                      = "txant"
    case txAntList                  = "tx_ant_list"
    case txOffsetFreq               = "tx_offset_freq"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case xitEnabled                 = "xit_on"
    case xitOffset                  = "xit_freq"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private let _log = LogProxy.sharedInstance.log

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Parse a Slice status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  public func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // get the Id
    if let id = properties[0].key.objectId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if slices[id: id] == nil {
          // create a new Slice & add it to the Slices collection
          slices[id: id] = Slice(id)
        }
        // pass the remaining key values to the Slice for parsing
        parseProperties(id, properties: Array(properties.dropFirst(1)) )
        
      } else {
        // does it exist?
        if slices[id: id] != nil {
          // YES, remove it
          slices[id: id] = nil
          _log("Slice \(id) removed", .debug, #function, #file, #line)
        }
      }
    }
  }
  
  /// Remove the specified Slice
  /// - Parameter id:     a SliceId
  public func remove(_ id: SliceId) {
    slices.remove(id: id)
    updateViewModel()
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  /// Parse Slice key/value pairs    ///
  /// - Parameter properties:       a KeyValuesArray
  private func parseProperties(_ id: SliceId, properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = SliceTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Slice \(id) unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .active:                   slices[id: id]!.active = property.value.bValue
      case .agcMode:                  slices[id: id]!.agcMode = property.value
      case .agcOffLevel:              slices[id: id]!.agcOffLevel = property.value.iValue
      case .agcThreshold:             slices[id: id]!.agcThreshold = property.value.dValue
      case .anfEnabled:               slices[id: id]!.anfEnabled = property.value.bValue
      case .anfLevel:                 slices[id: id]!.anfLevel = property.value.iValue
      case .apfEnabled:               slices[id: id]!.apfEnabled = property.value.bValue
      case .apfLevel:                 slices[id: id]!.apfLevel = property.value.iValue
      case .audioGain:                slices[id: id]!.audioGain = property.value.dValue
      case .audioLevel:               slices[id: id]!.audioGain = property.value.dValue
      case .audioMute:                slices[id: id]!.audioMute = property.value.bValue
      case .audioPan:                 slices[id: id]!.audioPan = property.value.dValue
      case .clientHandle:             slices[id: id]!.clientHandle = property.value.handle ?? 0
      case .daxChannel:
        if slices[id: id]!.daxChannel != 0 && property.value.iValue == 0 {
          // remove this slice from the AudioStream it was using
//          if let daxRxAudioStream = radio.findDaxRxAudioStream(with: daxChannel) { daxRxAudioStream.slice = nil }
        }
        slices[id: id]!.daxChannel = property.value.iValue
      case .daxTxEnabled:             slices[id: id]!.daxTxEnabled = property.value.bValue
      case .detached:                 slices[id: id]!.detached = property.value.bValue
      case .dfmPreDeEmphasisEnabled:  slices[id: id]!.dfmPreDeEmphasisEnabled = property.value.bValue
      case .digitalLowerOffset:       slices[id: id]!.digitalLowerOffset = property.value.iValue
      case .digitalUpperOffset:       slices[id: id]!.digitalUpperOffset = property.value.iValue
      case .diversityEnabled:         slices[id: id]!.diversityEnabled = property.value.bValue
      case .diversityChild:           slices[id: id]!.diversityChild = property.value.bValue
      case .diversityIndex:           slices[id: id]!.diversityIndex = property.value.iValue
        
      case .filterHigh:               slices[id: id]!.filterHigh = property.value.iValue
      case .filterLow:                slices[id: id]!.filterLow = property.value.iValue
      case .fmDeviation:              slices[id: id]!.fmDeviation = property.value.iValue
      case .fmRepeaterOffset:         slices[id: id]!.fmRepeaterOffset = property.value.fValue
      case .fmToneBurstEnabled:       slices[id: id]!.fmToneBurstEnabled = property.value.bValue
      case .fmToneMode:               slices[id: id]!.fmToneMode = property.value
      case .fmToneFreq:               slices[id: id]!.fmToneFreq = property.value.fValue
      case .frequency:                slices[id: id]!.frequency = property.value.mhzToHz
      case .ghost:                    _log("Slice: unprocessed property, \(property.key).\(property.value)", .warning, #function, #file, #line)
      case .inUse:                    slices[id: id]!.inUse = property.value.bValue
      case .locked:                   slices[id: id]!.locked = property.value.bValue
      case .loopAEnabled:             slices[id: id]!.loopAEnabled = property.value.bValue
      case .loopBEnabled:             slices[id: id]!.loopBEnabled = property.value.bValue
      case .mode:                     slices[id: id]!.mode = property.value.uppercased()
      case .modeList:                 slices[id: id]!.modeList = property.value
      case .nbEnabled:                slices[id: id]!.nbEnabled = property.value.bValue
      case .nbLevel:                  slices[id: id]!.nbLevel = property.value.iValue
      case .nrEnabled:                slices[id: id]!.nrEnabled = property.value.bValue
      case .nrLevel:                  slices[id: id]!.nrLevel = property.value.iValue
      case .nr2:                      slices[id: id]!.nr2 = property.value.iValue
      case .owner:                    slices[id: id]!.nr2 = property.value.iValue
      case .panadapterId:             slices[id: id]!.panadapterId = property.value.streamId ?? 0
      case .playbackEnabled:          slices[id: id]!.playbackEnabled = (property.value == "enabled") || (property.value == "1")
      case .postDemodBypassEnabled:   slices[id: id]!.postDemodBypassEnabled = property.value.bValue
      case .postDemodLow:             slices[id: id]!.postDemodLow = property.value.iValue
      case .postDemodHigh:            slices[id: id]!.postDemodHigh = property.value.iValue
      case .qskEnabled:               slices[id: id]!.qskEnabled = property.value.bValue
      case .recordEnabled:            slices[id: id]!.recordEnabled = property.value.bValue
      case .repeaterOffsetDirection:  slices[id: id]!.repeaterOffsetDirection = property.value
      case .rfGain:                   slices[id: id]!.rfGain = property.value.iValue
      case .ritOffset:                slices[id: id]!.ritOffset = property.value.iValue
      case .ritEnabled:               slices[id: id]!.ritEnabled = property.value.bValue
      case .rttyMark:                 slices[id: id]!.rttyMark = property.value.iValue
      case .rttyShift:                slices[id: id]!.rttyShift = property.value.iValue
      case .rxAnt:                    slices[id: id]!.rxAnt = property.value
      case .rxAntList:                slices[id: id]!.rxAntList = property.value.list
      case .sampleRate:               slices[id: id]!.sampleRate = property.value.iValue         // FIXME: ????? not in v3.2.15 source code
      case .sliceLetter:              slices[id: id]!.sliceLetter = property.value
      case .squelchEnabled:           slices[id: id]!.squelchEnabled = property.value.bValue
      case .squelchLevel:             slices[id: id]!.squelchLevel = property.value.iValue
      case .step:                     slices[id: id]!.step = property.value.iValue
      case .stepList:                 slices[id: id]!.stepList = property.value
      case .txEnabled:                slices[id: id]!.txEnabled = property.value.bValue
      case .txAnt:                    slices[id: id]!.txAnt = property.value
      case .txAntList:                slices[id: id]!.txAntList = property.value.list
      case .txOffsetFreq:             slices[id: id]!.txOffsetFreq = property.value.fValue
      case .wide:                     slices[id: id]!.wide = property.value.bValue
      case .wnbEnabled:               slices[id: id]!.wnbEnabled = property.value.bValue
      case .wnbLevel:                 slices[id: id]!.wnbLevel = property.value.iValue
      case .xitOffset:                slices[id: id]!.xitOffset = property.value.iValue
      case .xitEnabled:               slices[id: id]!.xitEnabled = property.value.bValue
        
        // the following are ignored here
      case .daxClients, .diversityParent, .recordTime: break
      }
    }
    if slices[id: id]!.initialized == false && slices[id: id]!.panadapterId != 0 && slices[id: id]!.frequency != 0 && slices[id: id]!.mode != "" {
      // mark it as initialized
      slices[id: id]!.initialized = true
      
      // notify all observers
      _log("Slice \(id) added: frequency = \( slices[id: id]!.frequency), panadapter = \( slices[id: id]!.panadapterId.hex)", .debug, #function, #file, #line)
    }
    updateViewModel()
  }
  
  /// Synchronize the viewModel
  private func updateViewModel() {
    Task {
      ViewModel.shared.slices = slices
    }
  }
}
