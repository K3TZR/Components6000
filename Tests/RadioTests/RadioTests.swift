//
//  RadioTests.swift
//  Components6000/RadioTests
//
//  Created by Douglas Adams on 2/11/20.
//

import XCTest
@testable import Radio

final class RadioTests: XCTestCase {
  
  // ------------------------------------------------------------------------------
  // MARK: - Amplifier
  
  ///   Format:  <Id, > <"ant", ant> <"ip", ip> <"model", model> <"port", port> <"serial_num", serialNumber>
  private var amplifierStatus = "0x12345678 ant=ANT1 ip=10.0.1.106 model=PGXL port=4123 serial_num=1234-5678-9012 state=STANDBY"
  
  func testAmplifierParse() {
    
    // give the parseStatus method the values (they will be updated on the main thread)
    Amplifier.parseStatus(amplifierStatus.keyValuesArray(), true)
    
    if let object = Objects.sharedInstance.amplifiers["0x12345678".streamId!] {
      
      XCTAssertEqual(object.id, "0x12345678".handle!, file: #function)
      XCTAssertEqual(object.ant, "ANT1", "ant", file: #function)
      XCTAssertEqual(object.ip, "10.0.1.106", file: #function)
      XCTAssertEqual(object.model, "PGXL", file: #function)
      XCTAssertEqual(object.port, 4123, file: #function)
      XCTAssertEqual(object.serialNumber, "1234-5678-9012", file: #function)
      XCTAssertEqual(object.state, "STANDBY", file: #function)
      
      object.ant = "ANT2"
      object.ip = "11.1.217"
      object.model = "QIYM"
      object.port = 3214
      object.serialNumber = "2109-8765-4321"
      
      XCTAssertEqual(object.id, "0x12345678".handle!, file: #function)
      XCTAssertEqual(object.ant, "ANT2", file: #function)
      XCTAssertEqual(object.ip, "11.1.217", file: #function)
      XCTAssertEqual(object.model, "QIYM", file: #function)
      XCTAssertEqual(object.port, 3214, file: #function)
      XCTAssertEqual(object.serialNumber, "2109-8765-4321", file: #function)
      XCTAssertEqual(object.state, "STANDBY", file: #function)
      
    } else {
      XCTFail("Amplifier not instantiated")
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Equalizer
  
  private var equalizerRxStatus = "rxsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  private var equalizerTxStatus = "txsc mode=0 63Hz=0 125Hz=10 250Hz=20 500Hz=30 1000Hz=-10 2000Hz=-20 4000Hz=-30 8000Hz=-40"
  
  func testEqualizerRxParse() {
    Objects.sharedInstance.equalizers[.rxsc] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    equalizerParse(.rxsc)
    Objects.sharedInstance.equalizers[.rxsc] = nil
  }
  
  func testEqualizerTxParse() {
    Objects.sharedInstance.equalizers[.txsc] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    equalizerParse(.txsc)
    Objects.sharedInstance.equalizers[.txsc] = nil
  }
  
  func equalizerParse(_ eqType: Equalizer.EqType) {
    
    // give the parseStatus method the values (they will be updated on the main thread)
    switch eqType {
    case .rxsc: Equalizer.parseStatus(equalizerRxStatus.keyValuesArray(), true)
    case .txsc: Equalizer.parseStatus(equalizerTxStatus.keyValuesArray(), true)
    default:
      XCTFail("Invalid Equalizer type - \(eqType.rawValue)", file: #function)
      return
    }
    
    if let object = Objects.sharedInstance.equalizers[eqType] {
      
      XCTAssertEqual(object.eqEnabled, false, "eqEnabled", file: #function)
      XCTAssertEqual(object.level63Hz, 0, "level63Hz", file: #function)
      XCTAssertEqual(object.level125Hz, 10, "level125Hz", file: #function)
      XCTAssertEqual(object.level250Hz, 20, "level250Hz", file: #function)
      XCTAssertEqual(object.level500Hz, 30, "level500Hz", file: #function)
      XCTAssertEqual(object.level1000Hz, -10, "level1000Hz", file: #function)
      XCTAssertEqual(object.level2000Hz, -20, "level2000Hz", file: #function)
      XCTAssertEqual(object.level4000Hz, -30, "level4000Hz", file: #function)
      XCTAssertEqual(object.level8000Hz, -40, "level8000Hz", file: #function)
      
    } else {
      XCTFail("Equalizer \(eqType) NOT found")
    }
    
  }
  
  
  func testEqualizerRx() {
    Objects.sharedInstance.equalizers[.rxsc] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    equalizer(.rxsc)
    Objects.sharedInstance.equalizers[.rxsc] = nil
  }
  
  func testEqualizerTx() {
    Objects.sharedInstance.equalizers[.txsc] = Equalizer(Equalizer.EqType.rxsc.rawValue)
    equalizer(.txsc)
    Objects.sharedInstance.equalizers[.txsc] = nil
  }
  
  func equalizer(_ eqType: Equalizer.EqType) {
    
    if let object = Objects.sharedInstance.equalizers[eqType] {
      
      object.eqEnabled = true
      object.level63Hz    = 10
      object.level125Hz   = -10
      object.level250Hz   = 15
      object.level500Hz   = -20
      object.level1000Hz  = 30
      object.level2000Hz  = -30
      object.level4000Hz  = 40
      object.level8000Hz  = -35
      
      XCTAssertEqual(object.eqEnabled, true, "eqEnabled", file: #function)
      XCTAssertEqual(object.level63Hz, 10, "level63Hz", file: #function)
      XCTAssertEqual(object.level125Hz, -10, "level125Hz", file: #function)
      XCTAssertEqual(object.level250Hz, 15, "level250Hz", file: #function)
      XCTAssertEqual(object.level500Hz, -20, "level500Hz", file: #function)
      XCTAssertEqual(object.level1000Hz, 30, "level1000Hz", file: #function)
      XCTAssertEqual(object.level2000Hz, -30, "level2000Hz", file: #function)
      XCTAssertEqual(object.level4000Hz, 40, "level4000Hz", file: #function)
      XCTAssertEqual(object.level8000Hz, -35, "level8000Hz", file: #function)
      
      object.eqEnabled = false
      object.level63Hz    = 0
      object.level125Hz   = 0
      object.level250Hz   = 0
      object.level500Hz   = 0
      object.level1000Hz  = 0
      object.level2000Hz  = 0
      object.level4000Hz  = 0
      object.level8000Hz  = 0
      
      XCTAssertEqual(object.eqEnabled, false, "eqEnabled", file: #function)
      XCTAssertEqual(object.level63Hz, 0, "level63Hz", file: #function)
      XCTAssertEqual(object.level125Hz, 0, "level125Hz", file: #function)
      XCTAssertEqual(object.level250Hz, 0, "level250Hz", file: #function)
      XCTAssertEqual(object.level500Hz, 0, "level500Hz", file: #function)
      XCTAssertEqual(object.level1000Hz, 0, "level1000Hz", file: #function)
      XCTAssertEqual(object.level2000Hz, 0, "level2000Hz", file: #function)
      XCTAssertEqual(object.level4000Hz, 0, "level4000Hz", file: #function)
      XCTAssertEqual(object.level8000Hz, 0, "level8000Hz", file: #function)
      
    } else {
      XCTFail("Equalizer type \(eqType) NOT found")
    }
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Memory
  
  private let memoryStatus = "1 owner=K3TZR group= freq=14.100000 name= mode=USB step=100 repeater=SIMPLEX repeater_offset=0.000000 tone_mode=OFF tone_value=67.0 power=100 rx_filter_low=100 rx_filter_high=2900 highlight=0 highlight_color=0x00000000 squelch=1 squelch_level=20 rtty_mark=2 rtty_shift=170 digl_offset=2210 digu_offset=1500"
  
  func testMemoryParse() {
    // give the parseStatus method the values (they will be updated on the main thread)
    Memory.parseStatus(memoryStatus.keyValuesArray(), true)
    
    if let object = Objects.sharedInstance.memories["1".objectId!] {
      
      XCTAssertEqual(object.owner, "K3TZR", "owner", file: #function)
      XCTAssertEqual(object.group, "", "Group", file: #function)
      XCTAssertEqual(object.frequency, 14_100_000, "frequency", file: #function)
      XCTAssertEqual(object.name, "", "name", file: #function)
      XCTAssertEqual(object.mode, "USB", "mode", file: #function)
      XCTAssertEqual(object.step, 100, "step", file: #function)
      XCTAssertEqual(object.offsetDirection, "SIMPLEX", "offsetDirection", file: #function)
      XCTAssertEqual(object.offset, 0, "offset", file: #function)
      XCTAssertEqual(object.toneMode, "OFF", "toneMode", file: #function)
      XCTAssertEqual(object.toneValue, 67.0, "toneValue", file: #function)
      XCTAssertEqual(object.filterLow, 100, "filterLow", file: #function)
      XCTAssertEqual(object.filterHigh, 2_900, "filterHigh", file: #function)
      //      XCTAssertEqual(object.highlight, false, "highlight", file: #function)
      //      XCTAssertEqual(object.highlightColor, "0x00000000".streamId, "highlightColor", file: #function)
      XCTAssertEqual(object.squelchEnabled, true, "squelchEnabled", file: #function)
      XCTAssertEqual(object.squelchLevel, 20, "squelchLevel", file: #function)
      XCTAssertEqual(object.rttyMark, 2, "rttyMark", file: #function)
      XCTAssertEqual(object.rttyShift, 170, "rttyShift", file: #function)
      XCTAssertEqual(object.digitalLowerOffset, 2210, "digitalLowerOffset", file: #function)
      XCTAssertEqual(object.digitalUpperOffset, 1500, "digitalUpperOffset", file: #function)
      
      object.owner = "DL3LSM"
      object.group = "X"
      object.frequency = 7_125_000
      object.name = "40"
      object.mode = "LSB"
      object.step = 212
      object.offsetDirection = "UP"
      object.offset = 10
      object.toneMode = "ON"
      object.toneValue = 76.0
      object.filterLow = 200
      object.filterHigh = 3_000
      //      object.highlight = true
      //      object.highlightColor = "0x01010101".streamId!
      object.squelchEnabled = false
      object.squelchLevel = 19
      object.rttyMark = 3
      object.rttyShift = 269
      object.digitalLowerOffset = 3321
      object.digitalUpperOffset = 2612
      
      XCTAssertEqual(object.owner, "DL3LSM", "owner", file: #function)
      XCTAssertEqual(object.group, "X", "group", file: #function)
      XCTAssertEqual(object.frequency, 7_125_000, "frequency", file: #function)
      XCTAssertEqual(object.name, "40", "name", file: #function)
      XCTAssertEqual(object.mode, "LSB", "mode", file: #function)
      XCTAssertEqual(object.step, 212, "step", file: #function)
      XCTAssertEqual(object.offsetDirection, "UP", "offsetDirection", file: #function)
      XCTAssertEqual(object.offset, 10, "offset", file: #function)
      XCTAssertEqual(object.toneMode, "ON", "toneMode", file: #function)
      XCTAssertEqual(object.toneValue, 76.0, "toneValue", file: #function)
      XCTAssertEqual(object.filterLow, 200, "filterLow", file: #function)
      XCTAssertEqual(object.filterHigh, 3_000, "filterHigh", file: #function)
      //      XCTAssertEqual(object.highlight, true, "highlight", file: #function)
      //      XCTAssertEqual(object.highlightColor, "0x01010101".streamId, "highlightColor", file: #function)
      XCTAssertEqual(object.squelchEnabled, false, "squelchEnabled", file: #function)
      XCTAssertEqual(object.squelchLevel, 19, "squelchLevel", file: #function)
      XCTAssertEqual(object.rttyMark, 3, "rttyMark", file: #function)
      XCTAssertEqual(object.rttyShift, 269, "rttyShift", file: #function)
      XCTAssertEqual(object.digitalLowerOffset, 3321, "digitalLowerOffset", file: #function)
      XCTAssertEqual(object.digitalUpperOffset, 2612, "digitalUpperOffset", file: #function)
      
    } else {
      XCTFail("Memory NOT not instantiated")
    }
    Objects.sharedInstance.memories.removeAll()
  }
  
  func testMemory() {
    
    // remove all
    Objects.sharedInstance.memories.removeAll()
    
    Objects.sharedInstance.memories[1] = Memory(1)
    
    if let object = Objects.sharedInstance.memories.first?.value {
      
      // save params
      let firstId = object.id
      
      let owner = object.owner
      let group = object.group
      let frequency = object.frequency
      let name = object.name
      let mode = object.mode
      let step = object.step
      let offsetDirection = object.offsetDirection
      let offset = object.offset
      let toneMode = object.toneMode
      let toneValue = object.toneValue
      let filterLow = object.filterLow
      let filterHigh = object.filterHigh
      //          let highlight = object.highlight
      //          let highlightColor = object.highlightColor
      let squelchEnabled = object.squelchEnabled
      let squelchLevel = object.squelchLevel
      let rttyMark = object.rttyMark
      let rttyShift = object.rttyShift
      let digitalLowerOffset = object.digitalLowerOffset
      let digitalUpperOffset = object.digitalUpperOffset
      
      Objects.sharedInstance.memories[firstId] = nil
      
      Objects.sharedInstance.memories[2] = Memory(2)
      
      if let object = Objects.sharedInstance.memories.first?.value {
        
        let secondId = object.id
        
        XCTAssertEqual(object.owner, owner, "owner", file: #function)
        XCTAssertEqual(object.group, group, "Group", file: #function)
        XCTAssertEqual(object.frequency, frequency, "frequency", file: #function)
        XCTAssertEqual(object.name, name, "name", file: #function)
        XCTAssertEqual(object.mode, mode, "mode", file: #function)
        XCTAssertEqual(object.step, step, "step", file: #function)
        XCTAssertEqual(object.offsetDirection, offsetDirection, "offsetDirection", file: #function)
        XCTAssertEqual(object.offset, offset, "offset", file: #function)
        XCTAssertEqual(object.toneMode, toneMode, "toneMode", file: #function)
        XCTAssertEqual(object.toneValue, toneValue, "toneValue", file: #function)
        XCTAssertEqual(object.filterLow, filterLow, "filterLow", file: #function)
        XCTAssertEqual(object.filterHigh, filterHigh, "filterHigh", file: #function)
        //                XCTAssertEqual(object.highlight, highlight, "highlight", file: #function)
        //                XCTAssertEqual(object.highlightColor, highlightColor, "highlightColor", file: #function)
        XCTAssertEqual(object.squelchEnabled, squelchEnabled, "squelchEnabled", file: #function)
        XCTAssertEqual(object.squelchLevel, squelchLevel, "squelchLevel", file: #function)
        XCTAssertEqual(object.rttyMark, rttyMark, "rttyMark", file: #function)
        XCTAssertEqual(object.rttyShift, rttyShift, "rttyShift", file: #function)
        XCTAssertEqual(object.digitalLowerOffset, digitalLowerOffset, "digitalLowerOffset", file: #function)
        XCTAssertEqual(object.digitalUpperOffset, digitalUpperOffset, "digitalUpperOffset", file: #function)
        
        object.owner = "DL3LSM"
        object.group = "X"
        object.frequency = 7_125_000
        object.name = "40"
        object.mode = "LSB"
        object.step = 212
        object.offsetDirection = "UP"
        object.offset = 10
        object.toneMode = "ON"
        object.toneValue = 76.0
        object.filterLow = 200
        object.filterHigh = 3_000
        //                object.highlight = true
        //                object.highlightColor = "0x01010101".streamId!
        object.squelchEnabled = false
        object.squelchLevel = 19
        object.rttyMark = 3
        object.rttyShift = 269
        object.digitalLowerOffset = 3321
        object.digitalUpperOffset = 2612
        
        XCTAssertEqual(object.owner, "DL3LSM", "owner", file: #function)
        XCTAssertEqual(object.group, "X", "group", file: #function)
        XCTAssertEqual(object.frequency, 7_125_000, "frequency", file: #function)
        XCTAssertEqual(object.name, "40", "name", file: #function)
        XCTAssertEqual(object.mode, "LSB", "mode", file: #function)
        XCTAssertEqual(object.step, 212, "step", file: #function)
        XCTAssertEqual(object.offsetDirection, "UP", "offsetDirection", file: #function)
        XCTAssertEqual(object.offset, 10, "offset", file: #function)
        XCTAssertEqual(object.toneMode, "ON", "toneMode", file: #function)
        XCTAssertEqual(object.toneValue, 76.0, "toneValue", file: #function)
        XCTAssertEqual(object.filterLow, 200, "filterLow", file: #function)
        XCTAssertEqual(object.filterHigh, 3_000, "filterHigh", file: #function)
        //                XCTAssertEqual(object.highlight, true, "highlight", file: #function)
        //                XCTAssertEqual(object.highlightColor, "0x01010101".streamId, "highlightColor", file: #function)
        XCTAssertEqual(object.squelchEnabled, false, "squelchEnabled", file: #function)
        XCTAssertEqual(object.squelchLevel, 19, "squelchLevel", file: #function)
        XCTAssertEqual(object.rttyMark, 3, "rttyMark", file: #function)
        XCTAssertEqual(object.rttyShift, 269, "rttyShift", file: #function)
        XCTAssertEqual(object.digitalLowerOffset, 3321, "digitalLowerOffset", file: #function)
        XCTAssertEqual(object.digitalUpperOffset, 2612, "digitalUpperOffset", file: #function)
        
        Objects.sharedInstance.memories[secondId] = nil
      }
    }
    Objects.sharedInstance.memories.removeAll()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Meter

  private let meterStatus = "1.src=COD-#1.num=1#1.nam=MICPEAK#1.low=-150.0#1.hi=20.0#1.desc=Signal strength of MIC output in CODEC#1.unit=dBFS#1.fps=40#"
  
  func testMeterParse() {
    // give the parseStatus method the values (they will be updated on the main thread)
    Meter.parseStatus(meterStatus.keyValuesArray(delimiter: "#"), true)
    
    if let object = Objects.sharedInstance.meters["1".objectId!] {
      
      XCTAssertEqual(object.source, "cod-", "source", file: #function)
      XCTAssertEqual(object.name, "micpeak", "name", file: #function)
      XCTAssertEqual(object.low, -150.0, "low", file: #function)
      XCTAssertEqual(object.high, 20.0, "high", file: #function)
      XCTAssertEqual(object.desc, "Signal strength of MIC output in CODEC", "desc", file: #function)
      XCTAssertEqual(object.units, "dbfs", "units", file: #function)
      XCTAssertEqual(object.fps, 40, "fps", file: #function)
      
    } else {
      XCTFail("Meter not instantiated")
    }
    Objects.sharedInstance.meters.removeAll()
  }
}
