//
//  RadioParsers.swift
//  Components6000/Radio
//
//  Created by Douglas Adams on 1/21/22.
//

import Foundation

import TcpCommands
import Shared

extension Radio {
  
  /// Parse  Command messages from the Radio
  /// - Parameter msg:        the Message String
  func receivedMessage(_ msg: TcpMessage) {
//  func receivedMessage(_ msg: TcpMessage) async {
    // get all except the first character
    let suffix = String(msg.text.dropFirst())
    
    // switch on the first character of the text
    switch msg.text[msg.text.startIndex] {
      
    case "H", "h":  connectionHandle = suffix.handle ; _log("Radio: connectionHandle = \(connectionHandle?.hex ?? "nil")", .debug, #function, #file, #line)
    case "M", "m":  parseMessage( msg.text.dropFirst() )
    case "R", "r":  parseReply( msg.text.dropFirst() )
//    case "S", "s":  await parseStatus( msg.text.dropFirst() )
    case "S", "s":  parseStatus( msg.text.dropFirst() )
    case "V", "v":  hardwareVersion = suffix ; _log("Radio: hardwareVersion = \(hardwareVersion ?? "unknown")", .debug, #function, #file, #line)
    default:        _log("Radio: unexpected message = \(msg)", .warning, #function, #file, #line)
    }
  }
  
  /// Parse a Message.
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  func parseMessage(_ msg: Substring) {
    // separate it into its components
    let components = msg.components(separatedBy: "|")
    
    // ignore incorrectly formatted messages
    if components.count < 2 {
      _log("Radio: incomplete message = c\(msg)", .warning, #function, #file, #line)
      return
    }
    let msgText = components[1]
    
    // log it
    _log("Radio: message = \(msgText)", flexErrorLevel(errorCode: components[0]), #function, #file, #line)
    
    // FIXME: Take action on some/all errors?
  }
  
  /// Parse a Reply
  /// - Parameters:
  ///   - commandSuffix:      a Reply Suffix
  func parseReply(_ replySuffix: Substring) {
    // separate it into its components
    let components = replySuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted replies
    if components.count < 2 {
      _log("Radio: incomplete reply, r\(replySuffix)", .warning, #function, #file, #line)
      return
    }
    // is there an Object expecting to be notified?
    if let replyTuple = replyHandlers[ components[0].uValue ] {
      // YES, an Object is waiting for this reply, send the Command to the Handler on that Object
      let command = replyTuple.command
      // was a Handler specified?
      if let handler = replyTuple.replyTo {
        // YES, call the Handler
        handler(command, components[0].sequenceNumber, components[1], (components.count == 3) ? components[2] : "")
        
      } else {
        // send it to the default reply handler
        defaultReplyHandler(replyTuple.command, sequenceNumber: components[0].sequenceNumber, responseValue: components[1], reply: (components.count == 3) ? components[2] : "")
      }
      // Remove the object from the notification list
      replyHandlers[components[0].sequenceNumber] = nil
      
    } else {
      // no Object is waiting for this reply, log it if it is a non-zero Reply (i.e a possible error)
      if components[1] != Shared.kNoError {
        _log("Radio: unhandled non-zero reply, c\(components[0]), r\(replySuffix), \(flexErrorString(errorCode: components[1]))", .warning, #function, #file, #line)
      }
    }
  }
  
  /// Parse a Status
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  func parseStatus(_ commandSuffix: Substring) {
//  func parseStatus(_ commandSuffix: Substring) async {
    // separate it into its components ( [0] = <apiHandle>, [1] = <remainder> )
    let components = commandSuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted status
    guard components.count > 1 else {
      _log("Radio: incomplete status = c\(commandSuffix)", .warning, #function, #file, #line)
      return
    }
    // find the space & get the msgType
    let spaceIndex = components[1].firstIndex(of: " ")!
    let msgType = String(components[1][..<spaceIndex])
    
    // everything past the msgType is in the remainder
    let remainderIndex = components[1].index(after: spaceIndex)
    let remainder = String(components[1][remainderIndex...])
    
    // Check for unknown Message Types
    guard let token = StatusTokens(rawValue: msgType)  else {
      // log it and ignore the message
      _log("Radio: unknown status token = \(msgType)", .warning, #function, #file, #line)
      return
    }
    // Known Message Types, in alphabetical order
    switch token {
      
    case .amplifier:      Amplifier.parseStatus(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
    case .atu:            objects.atu.parseProperties(remainder.keyValuesArray() )
    case .client:         parseClient(remainder.keyValuesArray(), !remainder.contains(Shared.kDisconnected))
    case .cwx:            objects.cwx.parseProperties(remainder.fix().keyValuesArray() )
    case .display:        parseDisplay(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
    case .eq:             Equalizer.parseStatus(remainder.keyValuesArray())
    case .file:           _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
    case .gps:            objects.gps.parseProperties(remainder.keyValuesArray(delimiter: "#") )
    case .interlock:      parseInterlock(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
    case .memory:         Memory.parseStatus(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
    case .meter:
      Task {
        await MeterCollection.shared.parseStatus(remainder.keyValuesArray(delimiter: "#"), !remainder.contains(Shared.kRemoved))
      }
    case .mixer:          _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
    case .profile:        Profile.parseStatus(remainder.keyValuesArray(delimiter: "="))
    case .radio:          parseProperties(remainder.keyValuesArray())
    case .slice:
      Task {
        await SliceCollection.shared.parseStatus(remainder.keyValuesArray(), !remainder.contains(Shared.kNotInUse))
      }
    case .stream:         parseStream(remainder)
    case .tnf:
      Task {
        await TnfCollection.shared.parseStatus(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
      }
//    case .tnf:            Tnf.parseStatus(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
    case .transmit:       parseTransmit(remainder.keyValuesArray(), !remainder.contains(Shared.kRemoved))
    case .turf:           _log("Radio, unprocessed \(msgType) message: \(remainder)", .warning, #function, #file, #line)
    case .usbCable:       UsbCable.parseStatus(remainder.keyValuesArray())
    case .wan:            objects.wan.parseProperties(remainder.keyValuesArray())
    case .waveform:       objects.waveform.parseProperties(remainder.keyValuesArray())
    case .xvtr:           Xvtr.parseStatus(remainder.keyValuesArray(), !remainder.contains(Shared.kNotInUse))
    }
    // is this status message the first for our handle?
    if !_clientInitialized && components[0].handle == connectionHandle {
      // YES, set the API state to finish the UDP initialization
      _clientInitialized = true
      updateState(to: .clientConnected)
    }
  }
  
  /// Parse a Client status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  func parseClient(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is there a valid handle"
    if let handle = properties[0].key.handle {
      switch properties[1].key {
        
      case Shared.kConnected:        parseConnection(properties: properties, handle: handle)
      case Shared.kDisconnected:     parseDisconnection(properties: properties, handle: handle)
      default:                    break
      }
    }
  }
  
  /// Parse a Display status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  private func parseDisplay(_ keyValues: KeyValuesArray, _ inUse: Bool = true) {
    switch keyValues[0].key {
      
    case DisplayTokens.panadapter.rawValue:
      Task {
        await PanadapterCollection.shared.parseStatus(keyValues, inUse)
      }
    case DisplayTokens.waterfall.rawValue:
      Task {
        await WaterfallCollection.shared.parseStatus(keyValues, inUse)
      }
      
    default:  _log("Radio, unknown display type: \(keyValues[0].key)", .warning, #function, #file, #line)
    }
  }
  
  func parseConnection(properties: KeyValuesArray, handle: Handle) {
    var clientId = ""
    var program = ""
    var station = ""
    var isLocalPtt = false
    
    func guiClientWasEdited(_ handle: Handle, _ client: GuiClient) {
      // log & notify if all essential properties are present
      if client.handle != 0 && client.clientId != nil && client.program != "" && client.station != "" {
        _log("Radio: guiClient updated: \(client.handle.hex), \(client.station), \(client.program), \(client.clientId!)", .info, #function, #file, #line)
        //              NC.post(.guiClientHasBeenUpdated, object: client as Any?)
      }
    }
    // parse remaining properties
    for property in properties.dropFirst(2) {
      
      // check for unknown Keys
      guard let token = ConnectionTokens(rawValue: property.key) else {
        // log it and ignore this Key
        _log("Radio, unknown client token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .clientId:         clientId = property.value
      case .localPttEnabled:  isLocalPtt = property.value.bValue
      case .program:          program = property.value.trimmingCharacters(in: .whitespaces)
      case .station:          station = property.value.replacingOccurrences(of: "\u{007f}", with: "").trimmingCharacters(in: .whitespaces)
      }
    }
    var handleWasFound = false
    // find the guiClient with the specified handle
    for (i, guiClient) in packet.guiClients.enumerated() where guiClient.handle == handle {
      handleWasFound = true
      
      // update any fields that are present
      if clientId != "" { packet.guiClients[id: handle]?.clientId = clientId }
      if program  != "" { packet.guiClients[id: handle]?.program = program }
      if station  != "" { packet.guiClients[id: handle]?.station = station }
      packet.guiClients[id: handle]?.isLocalPtt = isLocalPtt
      
      guiClientWasEdited(handle, packet.guiClients[i])
    }
    
    if handleWasFound == false {
      // GuiClient with the specified handle was not found, add it
      let client = GuiClient(handle: handle, station: station, program: program, clientId: clientId, isLocalPtt: isLocalPtt, isThisClient: handle == connectionHandle)
      packet.guiClients.append(client)
      
      // log and notify of GuiClient update
      _log("Radio: guiClient added, \(handle.hex), \(station), \(program), \(clientId)", .info, #function, #file, #line)
      //              NC.post(.guiClientHasBeenAdded, object: client as Any?)
      
      guiClientWasEdited(handle, client)
    }
  }
  
  func parseDisconnection(properties: KeyValuesArray, handle: Handle) {
    var reason = ""
    
    // is it me?
    if handle == connectionHandle {
      // parse remaining properties
      for property in properties.dropFirst(2) {
        // check for unknown Keys
        guard let token = DisconnectionTokens(rawValue: property.key) else {
          // log it and ignore this Key
          _log("Radio, unknown client disconnection token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known keys, in alphabetical order
        switch token {
          
        case .duplicateClientId:    if property.value.bValue { reason = "Duplicate ClientId" }
        case .forced:               if property.value.bValue { reason = "Forced" }
        case .wanValidationFailed:  if property.value.bValue { reason = "Wan validation failed" }
        }
        updateState(to: .clientDisconnected)
        //              NC.post(.clientDidDisconnect, object: reason as Any?)
      }
    }
  }

  /// Parse an Interlock status message
  /// - Parameters:
  ///   - radio:          the current Radio class
  ///   - properties:     a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  func parseInterlock(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is it a Band Setting?
    if properties[0].key == "band" {
      // YES, drop the "band", pass it to BandSetting
      BandSetting.parseStatus(Array(properties.dropFirst()), inUse )
      
    } else {
      // NO, pass it to Interlock
      objects.interlock.parseProperties(properties)
      interlockStateChange(objects.interlock.state)
    }
  }
  
  /// Parse the Reply to an Info command
  ///   executed on the parseQ
  ///
  /// - Parameters:
  ///   - properties:          a KeyValuesArray
  func parseInfoReply(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = InfoTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Radio, unknown info token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .atuPresent:       atuPresent = property.value.bValue
      case .callsign:         callsign = property.value
      case .chassisSerial:    chassisSerial = property.value
      case .gateway:          gateway = property.value
      case .gps:              gpsPresent = (property.value != "Not Present")
      case .ipAddress:        ipAddress = property.value
      case .location:         location = property.value
      case .macAddress:       macAddress = property.value
      case .model:            radioModel = property.value
      case .netmask:          netmask = property.value
      case .name:             nickname = property.value
      case .numberOfScus:     numberOfScus = property.value.iValue
      case .numberOfSlices:   numberOfSlices = property.value.iValue
      case .numberOfTx:       numberOfTx = property.value.iValue
      case .options:          radioOptions = property.value
      case .region:           region = property.value
      case .screensaver:      radioScreenSaver = property.value
      case .softwareVersion:  softwareVersion = property.value
      }
    }
  }
  
  /// Parse a Transmit status message
  /// - Parameters:
  ///   - radio:          the current Radio class
  ///   - properties:     a KeyValuesArray
  ///   - inUse:          false = "to be deleted"
  private func parseTransmit(_ properties: KeyValuesArray, _ inUse: Bool = true) {
    // is it a Band Setting?
    if properties[0].key == "band" {
      // YES, drop the "band", pass it to BandSetting
      BandSetting.parseStatus(Array(properties.dropFirst()), inUse )
      
    } else {
      // NO, pass it to Transmit
      objects.transmit.parseProperties(properties)
    }
  }
  
  /// Parse the Reply to a Version command, reply format: <key=value>#<key=value>#...<key=value>
  /// - Parameters:
  ///   - properties:          a KeyValuesArray
  func parseVersionReply(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = VersionTokens(rawValue: property.key) else {
        // log it and ignore the Key
        _log("Radio, unknown version token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .smartSdrMB:   smartSdrMB = property.value
      case .picDecpu:     picDecpuVersion = property.value
      case .psocMbTrx:    psocMbtrxVersion = property.value
      case .psocMbPa100:  psocMbPa100Version = property.value
      case .fpgaMb:       fpgaMbVersion = property.value
      }
    }
  }
  
  /// Parse a Radio status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  func parseProperties(_ properties: KeyValuesArray) {
    // separate by category
    if let category = RadioSubTokens(rawValue: properties[0].key) {
      // drop the first property
      let adjustedProperties = Array(properties[1...])
      
      switch category {
        
      case .filterSharpness:  parseFilterProperties( adjustedProperties )
      case .staticNetParams:  parseStaticNetProperties( adjustedProperties )
      case .oscillator:       parseOscillatorProperties( adjustedProperties )
      }
      
    } else {
      // process each key/value pair, <key=value>
      for property in properties {
        // Check for Unknown Keys
        guard let token = RadioTokens(rawValue: property.key)  else {
          // log it and ignore the Key
          _log("Radio, unknown token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
          continue
        }
        // Known tokens, in alphabetical order
        switch token {
          
        case .backlight:                backlight = property.value.iValue
        case .bandPersistenceEnabled:   bandPersistenceEnabled = property.value.bValue
        case .binauralRxEnabled:        binauralRxEnabled = property.value.bValue
        case .calFreq:                  calFreq = property.value.dValue
        case .callsign:                 callsign = property.value
        case .daxIqAvailable:           daxIqAvailable = property.value.iValue
        case .daxIqCapacity:            daxIqCapacity = property.value.iValue
        case .enforcePrivateIpEnabled:  enforcePrivateIpEnabled = property.value.bValue
        case .freqErrorPpb:             freqErrorPpb = property.value.iValue
        case .fullDuplexEnabled:        fullDuplexEnabled = property.value.bValue
        case .frontSpeakerMute:         frontSpeakerMute = property.value.bValue
        case .headphoneGain:            headphoneGain = property.value.iValue
        case .headphoneMute:            headphoneMute = property.value.bValue
        case .lineoutGain:              lineoutGain = property.value.iValue
        case .lineoutMute:              lineoutMute = property.value.bValue
        case .muteLocalAudio:           muteLocalAudio = property.value.bValue
        case .nickname:                 nickname = property.value
        case .panadapters:              availablePanadapters = property.value.iValue
        case .pllDone:                  startCalibration = property.value.bValue
        case .radioAuthenticated:       radioAuthenticated = property.value.bValue
        case .remoteOnEnabled:          remoteOnEnabled = property.value.bValue
        case .rttyMark:                 rttyMark = property.value.iValue
        case .serverConnected:          serverConnected = property.value.bValue
        case .slices:                   availableSlices = property.value.iValue
        case .snapTuneEnabled:          snapTuneEnabled = property.value.bValue
        case .tnfsEnabled:              tnfsEnabled = property.value.bValue
        }
      }
    }
    // is the Radio initialized?
    if !_radioInitialized {
      // YES, notify all observers
      _radioInitialized = true
    }
  }
  
  /// Parse a Filter Properties status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  private func parseFilterProperties(_ properties: KeyValuesArray) {
    var cw = false
    var digital = false
    var voice = false
    
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = FilterSharpnessTokens(rawValue: property.key.lowercased())  else {
        // log it and ignore the Key
        _log("Radio, unknown filter token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .cw:       cw = true
      case .digital:  digital = true
      case .voice:    voice = true
        
      case .autoLevel:
        if cw       { filterCwAutoEnabled = property.value.bValue ; cw = false }
        if digital  { filterDigitalAutoEnabled = property.value.bValue ; digital = false }
        if voice    { filterVoiceAutoEnabled = property.value.bValue ; voice = false }
      case .level:
        if cw       { filterCwLevel = property.value.iValue }
        if digital  { filterDigitalLevel = property.value.iValue  }
        if voice    { filterVoiceLevel = property.value.iValue }
      }
    }
  }
  
  /// Parse a Stream status message
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - remainder:      the text of the status mesage
  private func parseStream(_ remainder: String) {
    let properties = remainder.keyValuesArray()
    
    if isForThisClient(properties, connectionHandle: connectionHandle) {
      
      // is the 1st KeyValue a StreamId?
      if let id = properties[0].key.streamId {
        // YES, is it a removal?
        if remainder.contains(Shared.kRemoved) {
          
          // removal, find the stream & remove it
          if objects.daxIqStreams[id: id] != nil          { DaxIqStream.parseStatus(properties, false)           ; return }
          if objects.daxMicAudioStreams[id: id] != nil    { DaxMicAudioStream.parseStatus(properties, false)     ; return }
          if objects.daxRxAudioStreams[id: id] != nil     { DaxRxAudioStream.parseStatus(properties, false)      ; return }
          if objects.daxTxAudioStreams[id: id] != nil     { DaxTxAudioStream.parseStatus(properties, false)      ; return }
          if objects.remoteRxAudioStreams[id: id] != nil  { RemoteRxAudioStream.parseStatus(properties, false)   ; return }
          if objects.remoteTxAudioStreams[id: id] != nil  { RemoteTxAudioStream.parseStatus(properties, false)   ; return }
          return
          
        } else {
          // NOT a removal, check for unknown Keys
          guard let token = StreamTypeTokens(rawValue: properties[1].value) else {
            // log it and ignore the Key
            _log("Radio, unknown Stream type: \(properties[1].value)", .warning, #function, #file, #line)
            return
          }
          switch token {
            
          case .daxIq:      DaxIqStream.parseStatus(properties)
          case .daxMic:     DaxMicAudioStream.parseStatus(properties)
          case .daxRx:      DaxRxAudioStream.parseStatus(properties)
          case .daxTx:      DaxTxAudioStream.parseStatus(properties)
          case .remoteRx:   RemoteRxAudioStream.parseStatus(properties)
          case .remoteTx:   RemoteTxAudioStream.parseStatus(properties)
          }
        }
      }
    }
  }
  
  /// Parse a Static Net Properties status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  private func parseStaticNetProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = StaticNetTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Radio, unknown static token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .gateway:  staticGateway = property.value
      case .ip:       staticIp = property.value
      case .netmask:  staticNetmask = property.value
      }
    }
  }
  
  /// Parse an Oscillator Properties status message
  /// - Parameters:
  ///   - properties:      a KeyValuesArray
  private func parseOscillatorProperties(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = OscillatorTokens(rawValue: property.key)  else {
        // log it and ignore the Key
        _log("Radio, unknown oscillator token: \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .extPresent:   extPresent = property.value.bValue
      case .gpsdoPresent: gpsdoPresent = property.value.bValue
      case .locked:       locked = property.value.bValue
      case .setting:      setting = property.value
      case .state:        state = property.value
      case .tcxoPresent:  tcxoPresent = property.value.bValue
      }
    }
  }
  
}
