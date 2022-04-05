//
//  Panadapter.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation
import CoreGraphics
import simd

import Shared

/// Panadapter implementation
///
///       creates a Panadapter instance to be used by a Client to support the
///       processing of a Panadapter. Panadapter objects are added / removed by the
///       incoming TCP messages. Panadapter objects periodically receive Panadapter
///       data in a UDP stream. They are collected in the panadapters
///       collection on the Radio object.
///

//public final class Panadapter: ObservableObject, Identifiable {
public struct Panadapter: Identifiable {

  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kMaxBins = 5120
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var id: PanadapterStreamId
  
  public internal(set) var antList = [String]()
  public internal(set) var clientHandle: Handle = 0
  public internal(set) var dbmValues = [LegendValue]()
  public internal(set) var delegate: StreamHandler?
  public internal(set) var fillLevel: Int = 0
  public internal(set) var freqValues = [LegendValue]()
  var _isStreaming = false
  public internal(set) var maxBw: Hz = 0
  public internal(set) var minBw: Hz = 0
  public internal(set) var preamp = ""
  public internal(set) var rfGainHigh = 0
  public internal(set) var rfGainLow = 0
  public internal(set) var rfGainStep = 0
  public internal(set) var rfGainValues = ""
  public internal(set) var waterfallId: UInt32 = 0
  public internal(set) var wide = false
  public internal(set) var wnbUpdating = false
  public internal(set) var xvtrLabel = ""
  
  public var average: Int = 0
  public var band: String = ""
  // FIXME: Where does autoCenter come from?
  public var bandwidth: Hz = 0
  public var bandZoomEnabled: Bool  = false
  public var center: Hz = 0
  public var daxIqChannel: Int = 0
  public var fps: Int = 0
  public var loggerDisplayEnabled: Bool = false
  public var loggerDisplayIpAddress: String = ""
  public var loggerDisplayPort: Int = 0
  public var loggerDisplayRadioNumber: Int = 0
  public var loopAEnabled: Bool = false
  public var loopBEnabled: Bool = false
  public var maxDbm: CGFloat = 0
  public var minDbm: CGFloat = 0
  public var rfGain: Int = 0
  public var rxAnt: String = ""
  public var segmentZoomEnabled: Bool = false
  public var weightedAverageEnabled: Bool = false
  public var wnbEnabled: Bool = false
  public var wnbLevel: Int = 0
  public var xPixels: CGFloat = 0
  public var yPixels: CGFloat = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let daxIqChoices = Radio.kDaxIqChannels
  static var q = DispatchQueue(label: "PanadapterSequenceQ")
  private var _expectedFrameNumber = -1
  private var _droppedPackets = 0
  private var _accumulatedBins = 0
  
  public struct LegendValue: Identifiable {
    public var id: CGFloat         // relative position 0...1
    public var label: String       // value to display
    public var value: CGFloat      // actual value
    public var lineCount: CGFloat
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal types
  
  enum PanadapterTokens : String {
    // on Panadapter
    case antList                    = "ant_list"
    case average
    case band
    case bandwidth
    case bandZoomEnabled            = "band_zoom"
    case center
    case clientHandle               = "client_handle"
    case daxIq                      = "daxiq"
    case daxIqChannel               = "daxiq_channel"
    case fps
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case maxBw                      = "max_bw"
    case maxDbm                     = "max_dbm"
    case minBw                      = "min_bw"
    case minDbm                     = "min_dbm"
    case preamp                     = "pre"
    case rfGain                     = "rfgain"
    case rxAnt                      = "rxant"
    case segmentZoomEnabled         = "segment_zoom"
    case waterfallId                = "waterfall"
    case weightedAverageEnabled     = "weighted_average"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case wnbUpdating                = "wnb_updating"
    case xPixels                    = "x_pixels"
    case xvtrLabel                  = "xvtr"
    case yPixels                    = "y_pixels"
    // ignored by Panadapter
    case available
    case capacity
    case daxIqRate                  = "daxiq_rate"
    // not sent in status messages
    case n1mmSpectrumEnable         = "n1mm_spectrum_enable"
    case n1mmAddress                = "n1mm_address"
    case n1mmPort                   = "n1mm_port"
    case n1mmRadio                  = "n1mm_radio"
  }
  private struct PayloadHeader {      // struct to mimic payload layout
    var startingBinNumber: UInt16
    var segmentBinCount: UInt16
    var binSize: UInt16
    var frameBinCount: UInt16
    var frameNumber: UInt32
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  @Atomic(0, q) private var index: Int
  //  private var _index = 0
  private var _initialized = false
  private let _log = LogProxy.sharedInstance.log
  private let _numberOfFrames = 16
  private var _frames = [PanadapterFrame]()
  private var _suppress = false
  
  private var _dbmStep: CGFloat = 10
  private var _dbmFormat = "%3.0f"
  private var _freqStep: CGFloat = 10_000
  private var _freqFormat = "%2.3f"
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: PanadapterStreamId) {
    self.id = id
    
    // allocate dataframes
    for _ in 0..<_numberOfFrames {
      _frames.append(PanadapterFrame(frameSize: Panadapter.kMaxBins))
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Process the Reply to an Rf Gain Info command, reply format: <value>,<value>,...<value>
  /// - Parameters:
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  mutating func rfGainReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
    // Anything other than 0 is an error
    guard responseValue == Shared.kNoError else {
      // log it and ignore the Reply
      _log("Panadapter, non-zero reply: \(command), \(responseValue), \(flexErrorString(errorCode: responseValue))", .warning, #function, #file, #line)
      return
    }
    // parse out the values
    let rfGainInfo = reply.valuesArray( delimiter: "," )
    rfGainLow = rfGainInfo[0].iValue
    rfGainHigh = rfGainInfo[1].iValue
    rfGainStep = rfGainInfo[2].iValue
  }
  
  
  func calcDbmValues() -> [LegendValue] {
    var dbmValues = [LegendValue]()
    
    var value = maxDbm
    let lineCount = (maxDbm - minDbm) / _dbmStep
    
    dbmValues.append( LegendValue(id: 0, label: String(format: _dbmFormat, value), value: value, lineCount: lineCount) )
    repeat {
      let next = value - _dbmStep
      value = next < minDbm ? minDbm : next
      let position = (maxDbm - value) / (maxDbm - minDbm)
      dbmValues.append( LegendValue(id: position, label: String(format: _dbmFormat, value), value: value, lineCount: lineCount) )
    } while value != minDbm
    return dbmValues
  }
  
  func calcFreqValues() -> [LegendValue] {
    var freqValues = [LegendValue]()
    
    let maxFreq = CGFloat(center + (bandwidth/2))
    let minFreq = CGFloat(center - (bandwidth/2))
    var value = maxFreq
    let lineCount = (maxFreq - minFreq) / _freqStep
    
    freqValues.append( LegendValue(id: 0, label: String(format: _freqFormat, value), value: value, lineCount: lineCount) )
    repeat {
      let next = value - _freqStep
      value = next < minFreq ? minFreq : next
      let position = (maxFreq - value) / (maxFreq - minFreq)
      freqValues.append( LegendValue(id: position, label: String(format: _freqFormat, value), value: value, lineCount: lineCount) )
    } while value != minFreq
    return freqValues
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Command methods
  
  //    public func remove(callback: ReplyHandler? = nil) {
  //        _api.send("display panafall remove \(id.hex)", replyTo: callback)
  //    }
  //    public func clickTune(_ frequency: Hz, callback: ReplyHandler? = nil) {
  //        // FIXME: ???
  //        _api.send("slice " + "m " + "\(frequency.hzToMhz)" + " pan=\(id.hex)", replyTo: callback)
  //    }
  //    public func requestRfGainInfo() {
  //        _api.send("display pan " + "rf_gain_info " + "\(id.hex)", replyTo: rfGainReplyHandler)
  //    }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Command methods
  
  //    private func panadapterSet(_ token: PanadapterTokens, _ value: Any) {
  //        _api.send("display panafall set " + "\(id.hex) " + token.rawValue + "=\(value)")
  //    }
  //    // alternate forms for commands that do not use the Token raw value in outgoing messages
  //    private func panadapterSet(_ tokenString: String, _ value: Any) {
  //        _api.send("display panafall set " + "\(id.hex) " + tokenString + "=\(value)")
  //    }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModelWithStream extension

//extension Panadapter: DynamicModelWithStream {
extension Panadapter {
  
  /// Parse a Panadapter status message
  ///   executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
//  class func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
  static func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    //get the Id
    if let id =  properties[1].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if Objects.sharedInstance.panadapters[id: id] == nil {
          // create a new object & add it to the collection
          Objects.sharedInstance.panadapters[id: id] = Panadapter(id)
        }
        // pass the remaining key values for parsing
        Objects.sharedInstance.panadapters[id: id]!.parseProperties(Array(properties.dropFirst(2)) )
        
      } else {
        // does it exist?
        if Objects.sharedInstance.panadapters[id: id] != nil {
          // YES, notify all observers
          //          NC.post(.panadapterWillBeRemoved, object: self as Any?)
        }
      }
    }
    //        }
  }
  
  /// Parse Panadapter key/value pairs
  ///   executes on the mainQ
  /// - Parameter properties:       a KeyValuesArray
  mutating func parseProperties(_ properties: KeyValuesArray) {
    _suppress = true
    
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = PanadapterTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Panadapter: unknown token, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
      case .antList:                antList = property.value.list
      case .average:                average = property.value.iValue
      case .band:                   band = property.value
      case .bandwidth:
        bandwidth = property.value.mhzToHz
        freqValues = calcFreqValues()
      case .bandZoomEnabled:        bandZoomEnabled = property.value.bValue
      case .center:
        center = property.value.mhzToHz
        dbmValues = calcDbmValues()
        freqValues = calcFreqValues()
      case .clientHandle:           clientHandle = property.value.handle ?? 0
      case .daxIq:                  daxIqChannel = property.value.iValue
      case .daxIqChannel:           daxIqChannel = property.value.iValue
      case .fps:                    fps = property.value.iValue
      case .loopAEnabled:           loopAEnabled = property.value.bValue
      case .loopBEnabled:           loopBEnabled = property.value.bValue
      case .maxBw:                  maxBw = property.value.mhzToHz
      case .maxDbm:                 maxDbm = property.value.cgValue
      case .minBw:                  minBw = property.value.mhzToHz
      case .minDbm:                 minDbm = property.value.cgValue
      case .preamp:                 preamp = property.value
      case .rfGain:                 rfGain = property.value.iValue
      case .rxAnt:                  rxAnt = property.value
      case .segmentZoomEnabled:     segmentZoomEnabled = property.value.bValue
      case .waterfallId:            waterfallId = property.value.streamId ?? 0
      case .wide:                   wide = property.value.bValue
      case .weightedAverageEnabled: weightedAverageEnabled = property.value.bValue
      case .wnbEnabled:             wnbEnabled = property.value.bValue
      case .wnbLevel:               wnbLevel = property.value.iValue
      case .wnbUpdating:            wnbUpdating = property.value.bValue
      case .xvtrLabel:              xvtrLabel = property.value
      case .available, .capacity, .daxIqRate, .xPixels, .yPixels:     break // ignored by Panadapter
      case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:  break // not sent in status messages
      }
    }
    // is the Panadapter initialized?∫
    if !_initialized && center != 0 && bandwidth != 0 && (minDbm != 0.0 || maxDbm != 0.0) {
      // YES, the Radio (hardware) has acknowledged this Panadapter
      _initialized = true
      
      // notify all observers
      _log("Panadapter: added, id = \(id.hex) center = \(center.hzToMhz), bandwidth = \(bandwidth.hzToMhz)", .debug, #function, #file, #line)
      //      NC.post(.panadapterHasBeenAdded, object: self as Any?)
    }
    _suppress = false
  }
  
  /// Process the Panadapter Vita struct
  ///      The payload of the incoming Vita struct is converted to a PanadapterFrame and
  ///      passed to the Panadapter Stream Handler
  ///
  /// - Parameters:
  ///   - vita:        a Vita struct
  mutating func vitaProcessor(_ vita: Vita, _ testMode: Bool = false) {
    if _isStreaming == false {
      _isStreaming = true
      // log the start of the stream
      _log("Panadapter: stream started, \(vita.streamId.hex)", .info, #function, #file, #line)
    }
    // NO, Bins are just beyond the payload
    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
    
    vita.payloadData.withUnsafeBytes { ptr in
      
      // map the payload to the Payload struct
      let hdr = ptr.bindMemory(to: PayloadHeader.self)
      
      let startingBinNumber = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
      let segmentBinCount = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
      let frameBinCount = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
      let frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))
      
      // validate the packet (could be incomplete at startup)
      if frameBinCount == 0 { return }
      if startingBinNumber + segmentBinCount > frameBinCount { return }
         
      // are we in the ApiTester?
      if testMode {
        // YES, are we waiting for the start of a frame?
        if _expectedFrameNumber == -1 {
          // YES, is it the start of a frame?
          if startingBinNumber == 0 {
            // YES, START OF A FRAME
            _expectedFrameNumber = frameNumber
          } else {
            // NO, NOT THE START OF A FRAME
            return
          }
        }
        // is it the expected frame?
        if _expectedFrameNumber == frameNumber {
          // IT IS THE EXPECTED FRAME, add its bins to the collection
          _accumulatedBins += segmentBinCount
          
          // is the frame complete?
          if _accumulatedBins == frameBinCount {
            // YES, expect the next frame
            _expectedFrameNumber += 1
            _accumulatedBins = 0
          }
          
        } else {
          // NOT THE EXPECTED FRAME, wait for the next start of frame
          _log("Waterfall: missing frame(s), expected = \(_expectedFrameNumber), received = \(frameNumber)", .warning, #function, #file, #line)
          _expectedFrameNumber = -1
          _accumulatedBins = 0
          return
        }


      } else {
        
        if _expectedFrameNumber != frameNumber {
          _droppedPackets += (frameNumber - _expectedFrameNumber)
          _log("Panadapter: missing frame(s), expected = \(_expectedFrameNumber), received = \(frameNumber), drop count = \(_droppedPackets)", .warning, #function, #file, #line)
          _expectedFrameNumber = frameNumber
        }
        
        vita.payloadData.withUnsafeBytes { ptr in
          // Swap the byte ordering of the data & place it in the bins
          for i in 0..<segmentBinCount {
            _frames[index].bins[i+startingBinNumber] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
          }
        }
        _accumulatedBins += segmentBinCount

        // is it a complete Frame?
        if _accumulatedBins == frameBinCount {
          _frames[index].frameBinCount = _accumulatedBins
          // YES, pass it to the delegate
          delegate?.streamHandler(_frames[index])
          
          // update the expected frame number & dataframe index
          _expectedFrameNumber += 1
          _accumulatedBins = 0
          $index.mutate { $0 += 1 ; $0 = $0 % _numberOfFrames }
        }
      }
    }
  }
}

/// Class containing Panadapter Stream data
///   populated by the Panadapter vitaHandler
public struct PanadapterFrame {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  //  public var startingBinNumber = 0     // Index of first bin
  //  public var segmentBinCount = 0       // Number of bins
  //  public var binSize = 0               // Bin size in bytes
  public var frameBinCount = 0         // number of bins in the complete frame
  //  public var frameNumber = 0           // Frame number
  public var bins = [UInt16]()         // Array of bin values
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a PanadapterFrame
  ///
  /// - Parameter frameSize:    max number of Panadapter samples
  public init(frameSize: Int) {
    // allocate the bins array
    self.bins = [UInt16](repeating: 0, count: frameSize)
  }
}
