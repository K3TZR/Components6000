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
import Commands
import Shared

@testable import Commands

class CommandsTests: XCTestCase {
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
  let testTcpStatus = TcpStatus(isConnected: true, host: "192.168.1.200", port: 4992, error: nil)

  func testLiveConnect() {
    var discoveryCancellable: AnyCancellable?
    var commandCancellable: AnyCancellable?
    var statusCancellable: AnyCancellable?
    var updates = [PacketChange]()
    var messages = [String]()
    var status = [TcpStatus]()

    let command = Command()

    discoveryCancellable = discovery.packetPublisher
      .sink { update in
        updates.append(update)
      }
    
    commandCancellable = command.receivedDataPublisher
      .sink { msg in
        messages.append(msg)
      }

    statusCancellable = command.statusPublisher
      .sink { tcpStatus in
        status.append(tcpStatus)
      }

    do {
      try discovery.startLanListener()
    } catch {
      XCTFail("Failed to start LanListener")
    }
    
    sleep(2)
    
    XCTAssert(updates.count == 1, "Failed to receive Discovery packet")

    XCTAssert( command.connect(updates[0].packet) == true, "Failed to connect")

    sleep(1)

    XCTAssert( status[0].isConnected == testTcpStatus.isConnected, "TCP status isConnected incorrect")
    XCTAssert( status[0].host == testTcpStatus.host, "TCP status Host incorrect")
    XCTAssert( status[0].port == testTcpStatus.port, "TCP status Port incorrect")
    XCTAssert( status[0].error == nil, "TCP status Error incorrect")

    // fix the testMessages handle value
    let handle = messages[1].dropFirst().dropLast()
    testMessages[1] = String(testMessages[1].dropFirst(9))
    testMessages[1] = "H\(handle)" + testMessages[1]
    for i in 3...11 {
      testMessages[i] = String(testMessages[i].dropFirst(9))
      testMessages[i] = "S\(handle)" + testMessages[i]
    }

    for (i, message) in messages.enumerated() {
      XCTAssert(message == testMessages[i], "Received message error, \(message) != \(testMessages[i])")
    }
    
    command.disconnect()

    commandCancellable?.cancel()
    statusCancellable?.cancel()
    discoveryCancellable?.cancel()
    discovery.packets = IdentifiedArrayOf<Packet>()
  }
  
//  func testSend() {
//
//  }
//
//  func testReceive() {
//
//  }
}
