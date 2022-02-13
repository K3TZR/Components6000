//
//  CommandsTest.swift
//  
//
//  Created by Douglas Adams on 12/24/21.
//

import XCTest
import ComposableArchitecture
import Combine

import Discovery
import TcpCommands
import Shared

@testable import TcpCommands

class TcpCommandsTests: XCTestCase {
  let discovery = Discovery.sharedInstance
  
  var testMessages = [
    "V1.4.0.0\n",
    "H32848110\n",
    "M10000001|Client connected from IP 192.168.1.213\n",
    "S32848110|radio slices=4 panadapters=4 lineout_gain=47 lineout_mute=0 headphone_gain=43 headphone_mute=1 remote_on_enabled=0 pll_done=0 freq_error_ppb=6 cal_freq=15.000000 tnf_enabled=1 snap_tune_enabled=1 nickname=DougsFlex callsign=K3TZR binaural_rx=0 full_duplex_enabled=0 band_persistence_enabled=1 rtty_mark_default=2 enforce_private_ip_connections=1 backlight=50 mute_local_audio_when_remote=1 daxiq_capacity=16 daxiq_available=16\n",
    "S32848110|radio filter_sharpness VOICE level=2 auto_level=1\n",
    "S32848110|radio filter_sharpness CW level=2 auto_level=1\n",
    "S32848110|radio filter_sharpness DIGITAL level=2 auto_level=1\n",
    "S32848110|radio static_net_params ip= gateway= netmask=\n",
    "S32848110|radio oscillator state=tcxo setting=tcxo locked=1\n",
    "S32848110|interlock acc_txreq_enable=0 rca_txreq_enable=0 acc_tx_enabled=1 tx1_enabled=1 tx2_enabled=1 tx3_enabled=1 tx_delay=0 acc_tx_delay=0 tx1_delay=0 tx2_delay=0 tx3_delay=0 acc_txreq_polarity=0 rca_txreq_polarity=0 timeout=0\n",
    "S32848110|eq rx mode=0 63Hz=10 125Hz=10 250Hz=10 500Hz=10 1000Hz=10 2000Hz=10 4000Hz=10 8000Hz=10\n",
    "S32848110|eq rxsc mode=0 63Hz=0 125Hz=0 250Hz=0 500Hz=0 1000Hz=0 2000Hz=0 4000Hz=0 8000Hz=0\n",
    "S0|interlock tx_client_handle=0x00000000 state=RECEIVE reason= source= tx_allowed=0 amplifier=\n"
  ]

  func testTcpLoopback() {
    var commandCancellable: AnyCancellable?
    var statusCancellable: AnyCancellable?
    var messages = [String]()
    var status = [TcpStatus]()

    // subscribe to Tcp messages (sent & received)
    let tcp = Tcp()
    commandCancellable = tcp.receivedPublisher
      .sink { tcpMessage in
        messages.append(tcpMessage.text)
      }

    // subscribe to Tcp status
    statusCancellable = tcp.statusPublisher
      .sink { tcpStatus in
        status.append(tcpStatus)
      }

    if tcp.connect(testPacket) {
      // wait to be connected
      sleep(1)

      if status.count == 1 {
        XCTAssert( status[0].statusType == testStatus.statusType, "TCP connection failed, \(status[0].error?.localizedDescription ?? "???")" )
        XCTAssert( status[0].host == testStatus.host, "TCP host error, \(status[0].host) != \(testStatus.host)" )
        XCTAssert( status[0].port == testStatus.port, "TCP port error, \(status[0].port) != \(testStatus.port)" )
        XCTAssert( status[0].error == nil, "TCP error, \(status[0].error!) != nil" )
        
        // send a message
        var sequenceNumber = tcp.send(testMessage1)
        
        sleep(1)
        
        if messages.count == 1 {
          XCTAssert(messages[0] == testMessage1, "Received message \(sequenceNumber) error, \(messages[0]) != \(testMessage1)" )
        } else {
          XCTFail("Failed to receive first message")
        }
        messages.removeAll()
        // send a message
        sequenceNumber = tcp.send(testMessage2)
        
        sleep(1)
        if messages.count == 1 {
          XCTAssert(messages[0] == testMessage1, "Received message \(sequenceNumber) error, \(messages[0]) != \(testMessage1)" )
        } else {
          XCTFail("Failed to receive second message")
        }
      } else {
        XCTFail("Failed to receive status")
      }
    } else {
      XCTFail("Failed to connect to Loopback address")
    }
    commandCancellable = nil
    statusCancellable = nil
    tcp.disconnect()
  }
  
//  func testTcpSmartlink() {
//    var commandCancellable: AnyCancellable?
//    var statusCancellable: AnyCancellable?
//    var messages = [String]()
//    var status = [TcpStatus]()
//
//    let tcp = Tcp()
//    commandCancellable = tcp.receivedPublisher
//      .sink { tcpMessage in
//        messages.append(tcpMessage.text)
//      }
//
//    statusCancellable = tcp.statusPublisher
//      .sink { tcpStatus in
//        status.append(tcpStatus)
//      }
//
//    if tcp.connect(testPacket) {
//      // wait to be connected
//      sleep(1)
//
//      XCTAssert( status[0].statusType == testStatus.statusType, "TCP connection failed" )
//      XCTAssert( status[0].host == testStatus.host, "TCP host error, \(status[0].host) != \(testStatus.host)" )
//      XCTAssert( status[0].port == testStatus.port, "TCP port error, \(status[0].port) != \(testStatus.port)" )
//      XCTAssert( status[0].error == nil, "TCP error, \(status[0].error!) != nil" )
//      
//      // send a message
//      let sequenceNumber = tcp.send(testMessage1)
//      
//      sleep(1)
//      
//      XCTAssert(messages[0] == testMessage1, "Received message \(sequenceNumber) error, \(messages[0]) != \(testMessage1)" )
//
//
//
//    } else {
//      XCTFail("Failed to connect to Loopback address")
//    }
//    commandCancellable = nil
//    statusCancellable = nil
//    tcp.disconnect()
//  }

//    discoveryCancellable = discovery.packetPublisher
//      .sink { update in
//        updates.append(update)
//      }
//
//
//    do {
//      try discovery.startLanListener()
//    } catch {
//      XCTFail("Failed to start LanListener")
//    }
//
//    sleep(2)
//
//    XCTAssert(updates.count == 1, "Failed to receive Discovery packet")
//
//    XCTAssert( tcp.connect(updates[0].packet) == true, "Failed to connect")
//
//    sleep(1)
//
//    XCTAssert( status[0].statusType == testTcpStatus.statusType, "TCP connection failed" )
//    XCTAssert( status[0].host == testTcpStatus.host, "TCP host error, \(status[0].host) != \(testTcpStatus.host)" )
//    XCTAssert( status[0].port == testTcpStatus.port, "TCP port error, \(status[0].port) != \(testTcpStatus.port)" )
//    XCTAssert( status[0].error == nil, "TCP error, \(status[0].error!) != nil" )
//
//    // fix the testMessages handle value
//    let handle = String(messages[1].dropFirst().dropLast())
//    testMessages[1] = String(testMessages[1].dropFirst(9))
//    testMessages[1] = "H\(handle)" + testMessages[1]
//    for i in 3...11 {
//      testMessages[i] = String(testMessages[i].dropFirst(9))
//      testMessages[i] = "S\(handle)" + testMessages[i]
//    }
//
//    for (i, message) in messages.enumerated() {
//      XCTAssert(message == testMessages[i], "Received message error, \(message) != \(testMessages[i])" )
//    }
//
//    tcp.disconnect()
//
//    commandCancellable?.cancel()
//    statusCancellable?.cancel()
//    discoveryCancellable?.cancel()
//    discovery.packets = IdentifiedArrayOf<Packet>()
//  }
//
////  func testSend() {
//
//  }
//
//  func testReceive() {
//
//  }

  var testStatus: TcpStatus {
    TcpStatus(.didConnect, host: "127.0.0.1", port: 4992, error: nil, reason: nil)
  }
  
  var testPacket: Packet {
    var packet = Packet()
    packet.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    packet.nickname = "Loopback"
    packet.port = 7
    packet.source = .local
    packet.serial = "1234-5678-9012-3456"
    packet.publicIp = "127.0.0.1"
    return packet
  }

  var testPacket2: Packet {
    var packet = Packet()
    packet.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    packet.nickname = "Smartlink"
    packet.port = 7
    packet.source = .smartlink
    packet.serial = "1234-5678-9012-3456"
    packet.publicTlsPort = 40000000
    return packet
  }

  var testMessage1: String {
    "This is test message1 param1=someValue1 params2=someValue2"
  }
  
  var testMessage2: String {
    """
    This is test message1 param1=someValue1 params2=someValue2
    ping this is a ping message
    """
  }
}
