//
//  Waterfall.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation
import CoreGraphics

import Shared

/// Waterfall Class implementation
///
///       creates a Waterfall instance to be used by a Client to support the
///       processing of a Waterfall. Waterfall objects are added / removed by the
///       incoming TCP messages. Waterfall objects periodically receive Waterfall
///       data in a UDP stream. They are collected in the waterfalls collection
///       on the Radio object.
///

public final class Waterfall: ObservableObject, Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public internal(set) var id: WaterfallStreamId
  
  public internal(set) var autoBlackEnabled = false
  public internal(set) var autoBlackLevel: UInt32 = 0
  public internal(set) var blackLevel = 0
  public internal(set) var clientHandle: Handle = 0
  public internal(set) var colorGain = 0
  public internal(set) var delegate: StreamHandler?
  public internal(set) var gradientIndex = 0
  var _isStreaming = false
  public internal(set) var lineDuration = 0
  public internal(set) var panadapterId: PanadapterStreamId?
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  static var q = DispatchQueue(label: "WaterfallSequenceQ", attributes: [.concurrent])
  private var _expectedFrameNumber = -1
  private var _droppedPackets = 0
  private var _accumulatedBins = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  enum WaterfallTokens : String {
    case clientHandle         = "client_handle"   // New Api only
    
    // on Waterfall
    case autoBlackEnabled     = "auto_black"
    case blackLevel           = "black_level"
    case colorGain            = "color_gain"
    case gradientIndex        = "gradient_index"
    case lineDuration         = "line_duration"
    
    // unused here
    case available
    case band
    case bandZoomEnabled      = "band_zoom"
    case bandwidth
    case capacity
    case center
    case daxIq                = "daxiq"
    case daxIqChannel         = "daxiq_channel"
    case daxIqRate            = "daxiq_rate"
    case loopA                = "loopa"
    case loopB                = "loopb"
    case panadapterId         = "panadapter"
    case rfGain               = "rfgain"
    case rxAnt                = "rxant"
    case segmentZoomEnabled   = "segment_zoom"
    case wide
    case xPixels              = "x_pixels"
    case xvtr
  }
  private struct PayloadHeader {  // struct to mimic payload layout
    var firstBinFreq: UInt64    // 8 bytes
    var binBandwidth: UInt64    // 8 bytes
    var lineDuration : UInt32   // 4 bytes
    var segmentBinCount: UInt16    // 2 bytes
    var height: UInt16          // 2 bytes
    var frameNumber: UInt32   // 4 bytes
    var autoBlackLevel: UInt32  // 4 bytes
    var frameBinCount: UInt16       // 2 bytes
    var startingBinNumber: UInt16        // 2 bytes
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _frames = [WaterfallFrame]()
  @Atomic(0, q) private var index: Int
  private var _initialized = false
  private let _log = LogProxy.sharedInstance.log
  private let _numberOfFrames = 10
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: WaterfallStreamId) {
    self.id = id
    
    // allocate two dataframes
    for _ in 0..<_numberOfFrames {
      _frames.append(WaterfallFrame(frameSize: 4096))
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - DynamicModel extension

//extension Waterfall: DynamicModelWithStream {
extension Waterfall {
  /// Parse a Waterfall status message
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // get the Id
    if let id = properties[1].key.streamId {
      // is the object in use?
      if inUse {
        // YES, does it exist?
        if Objects.sharedInstance.waterfalls[id: id] == nil {
          // Create a Waterfall & add it to the Waterfalls collection
          Objects.sharedInstance.waterfalls[id: id] = Waterfall(id)
        }
        // pass the key values to the Waterfall for parsing (dropping the Type and Id)
        Objects.sharedInstance.waterfalls[id: id]!.parseProperties(Array(properties.dropFirst(2)))
        
      } else {
        // does it exist?
        if Objects.sharedInstance.waterfalls[id: id] != nil {
          // YES, remove the Panadapter & Waterfall, notify all observers
          if let panId = Objects.sharedInstance.waterfalls[id: id]!.panadapterId {
            
            Objects.sharedInstance.panadapters[id: panId] = nil
            
            LogProxy.sharedInstance.log("Panadapter, removed: id = \(panId.hex)", .debug, #function, #file, #line)
            //            NC.post(.panadapterHasBeenRemoved, object: id as Any?)
            
            //            NC.post(.waterfallWillBeRemoved, object: radio.waterfalls[id] as Any?)
            
            Objects.sharedInstance.waterfalls[id: id] = nil
            
            LogProxy.sharedInstance.log("Waterfall, removed: id = \(id.hex)", .debug, #function, #file, #line)
            //            NC.post(.waterfallHasBeenRemoved, object: id as Any?)
          }
        }
      }
    }
  }
  
  /// Parse Waterfall key/value pairs
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = WaterfallTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Waterfall, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .autoBlackEnabled:   autoBlackEnabled = property.value.bValue
      case .blackLevel:         blackLevel = property.value.iValue
      case .clientHandle:       clientHandle = property.value.handle ?? 0
      case .colorGain:          colorGain = property.value.iValue
      case .gradientIndex:      gradientIndex = property.value.iValue
      case .lineDuration:       lineDuration = property.value.iValue
      case .panadapterId:       panadapterId = property.value.streamId ?? 0
        // the following are ignored here
      case .available, .band, .bandwidth, .bandZoomEnabled, .capacity, .center, .daxIq, .daxIqChannel,
          .daxIqRate, .loopA, .loopB, .rfGain, .rxAnt, .segmentZoomEnabled, .wide, .xPixels, .xvtr:  break
      }
    }
    // is the waterfall initialized?
    if !_initialized && panadapterId != 0 {
      // YES, the Radio (hardware) has acknowledged this Waterfall
      _initialized = true
      
      // notify all observers
      _log("Waterfall, added: id = \(id.hex), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
      //      NC.post(.waterfallHasBeenAdded, object: self as Any?)
    }
  }
  
  /// Process the Waterfall Vita struct
  ///
  ///   VitaProcessor protocol method, executes on the streamQ
  ///      The payload of the incoming Vita struct is converted to a WaterfallFrame and
  ///      passed to the Waterfall Stream Handler, called by Radio
  ///
  /// - Parameters:
  ///   - vita:       a Vita struct
  func vitaProcessor(_ vita: Vita, _ testMode: Bool = false) {
    if _isStreaming == false {
      _isStreaming = true
      // log the start of the stream
      _log("Waterfall: stream started, \(vita.streamId.hex)", .info, #function, #file, #line)
    }
    
    // Bins are just beyond the payload
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
   
      // is it the start of a frame?
      if _expectedFrameNumber == -1 && startingBinNumber == 0 { _expectedFrameNumber = frameNumber }
      
      if _expectedFrameNumber == -1 {
        // NO, ignore any partial frame
        _log("Waterfall: incomplete frame = \(frameNumber), startingBin = \(startingBinNumber)", .debug, #function, #file, #line)
        return
      }
      
      // are we in the ApiTester?
      if testMode {
        // APITESTER MODE
        if _expectedFrameNumber != frameNumber {
          _log("Waterfall: missing frame(s), expected = \(_expectedFrameNumber), received = \(frameNumber), total drops = \(_droppedPackets)", .warning, #function, #file, #line)
          _droppedPackets += (frameNumber - _expectedFrameNumber)
        }
        _accumulatedBins += segmentBinCount
        
        // increment the expected frame number if the entire frame has been accumulated
        if _accumulatedBins == frameBinCount { _expectedFrameNumber += 1 ; _accumulatedBins = 0 }
        
      } else {
        // NORMAL MODE
        // populate frame values
        _frames[index].firstBinFreq = CGFloat(CFSwapInt64BigToHost(hdr[0].firstBinFreq)) / 1.048576E6
        _frames[index].binBandwidth = CGFloat(CFSwapInt64BigToHost(hdr[0].binBandwidth)) / 1.048576E6
        _frames[index].lineDuration = Int( CFSwapInt32BigToHost(hdr[0].lineDuration) )
        _frames[index].height = Int( CFSwapInt16BigToHost(hdr[0].height) )
        _frames[index].autoBlackLevel = CFSwapInt32BigToHost(hdr[0].autoBlackLevel)
             
        if _expectedFrameNumber != frameNumber {
          _droppedPackets += (frameNumber - _expectedFrameNumber)
          _log("Waterfall: missing frame(s), expected = \(_expectedFrameNumber), received = \(frameNumber), drop count = \(_droppedPackets)", .warning, #function, #file, #line)
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

/// Class containing Waterfall Stream data
///
///   populated by the Waterfall vitaHandler
public struct WaterfallFrame {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var firstBinFreq: CGFloat = 0.0  // Frequency of first Bin (Hz)
  public var binBandwidth: CGFloat = 0.0  // Bandwidth of a single bin (Hz)
  public var lineDuration  = 0            // Duration of this line (ms)
  //  public var segmentBinCount = 0          // Number of bins
  public var height = 0                   // Height of frame (pixels)
  //  public var frameNumber = 0              // Time code
  public var autoBlackLevel: UInt32 = 0   // Auto black level
  public var frameBinCount = 0            //
  //  public var startingBinNumber = 0        //
  public var bins = [UInt16]()            // Array of bin values
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a WaterfallFrame
  ///
  /// - Parameter frameSize:    max number of Waterfall samples
  ///
  public init(frameSize: Int) {
    // allocate the bins array
    self.bins = [UInt16](repeating: 0, count: frameSize)
  }
}
