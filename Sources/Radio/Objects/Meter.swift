//
//  Meter.swift
//  Components6000/Radio/Objects
//
//  Created by Douglas Adams on 6/2/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation
import Combine

import Shared

/// Meter Struct implementation
///
///      A Meter instance to be used by a Client to support the
///      rendering of a Meter. They are collected in the
///      metersCollection global actor.
///
public struct Meter: Identifiable, Equatable {
  public static func == (lhs: Meter, rhs: Meter) -> Bool {
    lhs.id == rhs.id
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public internal(set) var id: MeterId
  public internal(set) var initialized: Bool = false

  public internal(set) var desc = ""
  public internal(set) var fps = 0
  public internal(set) var high: Float = 0
  public internal(set) var low: Float = 0
  public internal(set) var group = ""
  public internal(set) var name = ""
  public internal(set) var peak: Float = 0
  public internal(set) var source = ""
  public internal(set) var units = ""
  public internal(set) var value: Float = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public enum Source: String {
    case codec      = "cod"
    case tx
    case slice      = "slc"
    case radio      = "rad"
    case amplifier  = "amp"
  }
  public enum ShortName : String, CaseIterable {
    case codecOutput            = "codec"
    case microphoneAverage      = "mic"
    case microphoneOutput       = "sc_mic"
    case microphonePeak         = "micpeak"
    case postClipper            = "comppeak"
    case postFilter1            = "sc_filt_1"
    case postFilter2            = "sc_filt_2"
    case postGain               = "gain"
    case postRamp               = "aframp"
    case postSoftwareAlc        = "alc"
    case powerForward           = "fwdpwr"
    case powerReflected         = "refpwr"
    case preRamp                = "b4ramp"
    case preWaveAgc             = "pre_wave_agc"
    case preWaveShim            = "pre_wave"
    case signal24Khz            = "24khz"
    case signalPassband         = "level"
    case signalPostNrAnf        = "nr/anf"
    case signalPostAgc          = "agc+"
    case swr                    = "swr"
    case temperaturePa          = "patemp"
    case voltageAfterFuse       = "+13.8b"
    case voltageBeforeFuse      = "+13.8a"
    case voltageHwAlc           = "hwalc"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: MeterId) { self.id = id }
}
