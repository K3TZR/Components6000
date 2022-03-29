//
//  RemoteScripts.swift
//  Components6000/RemoteViewer
//
//  Created by Douglas Adams on 3/29/22.
//

import Foundation

let scripts =
"""
\(cycleOnScript.source)

\(cycleOffScript.source)
"""

let cycleOnScript = RelayScript(
  type: .cycleOn,
  duration: 7,
  source:
    """
    function cycle_on()
      outlet[1].on()
      delay(1)
      outlet[2].on()
      delay(5)
      outlet[3].on()
    end
    """,
  msg: "while the Cycle ON script executes"
)

let cycleOffScript = RelayScript(
  type: .cycleOff,
  duration: 7,
  source:
    """
    function cycle_off()
      outlet[3].off()
      delay(5)
      outlet[2].off()
      delay(1)
      outlet[1].off()
    end
    """,
  msg: "while the Cycle OFF script executes"
)
