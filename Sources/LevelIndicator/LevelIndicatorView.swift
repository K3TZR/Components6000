//
//  LevelIndicatorView.swift
//  Components6000/LevelIndicator
//
//  Created by Douglas Adams on 4/29/22.
//

import Foundation
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - Structs and Enums

public struct Tick {
  public var value: CGFloat  // 0...1
  public var label: String

  public init
  (
    value: CGFloat,
    label: String
  )
  {
    self.value = value
    self.label = label
  }
}

public struct IndicatorStyle {
  var width: CGFloat
  var height: CGFloat
  var isFlipped: Bool
  var min: CGFloat
  var max: CGFloat
  var warningLevel: CGFloat     // min...max
  var criticalLevel: CGFloat    // min...max
  var backgroundColor: Color
  var normalColor: Color
  var warningColor: Color
  var criticalColor: Color
  var borderColor: Color
  var tickColor: Color
  var legendFont: Font
  var legendColor: Color
  var ticks: [Tick]
  
  public init
  (
    width: CGFloat = 140,
    height: CGFloat = 10,
    isFlipped: Bool = false,
    min: CGFloat = 0.0,
    max: CGFloat = 1.0,
    warningLevel: CGFloat = 0.6,
    criticalLevel: CGFloat = 0.9,
    backgroundColor: Color = .clear,
    normalColor: Color = .green,
    warningColor: Color = .yellow,
    criticalColor: Color = .red,
    borderColor: Color = .blue,
    tickColor: Color = .blue,
    legendFont: Font = .custom("Monaco", fixedSize: 8),
    legendColor: Color = .orange,
    ticks: [Tick] = []
  )
  {
    self.width = width
    self.height = height
    self.isFlipped = isFlipped
    self.min = min
    self.max = max
    self.warningLevel = warningLevel
    self.criticalLevel = criticalLevel
    self.backgroundColor = backgroundColor
    self.normalColor = normalColor
    self.warningColor = warningColor
    self.criticalColor = criticalColor
    self.borderColor = borderColor
    self.tickColor = tickColor
    self.legendFont = legendFont
    self.legendColor = legendColor
    self.ticks = ticks
    
    
  }
}

let rfPowerStyle = IndicatorStyle(
  width: 160,
  height: 10,
  isFlipped: false,
  max: 1.2,
  warningLevel: 1.0,
  criticalLevel: 1.0,
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:0.1, label: ""),
      Tick(value:0.2, label: ""),
      Tick(value:0.3, label: ""),
      Tick(value:0.4, label: "40"),
      Tick(value:0.50, label: "RF Power"),
      Tick(value:0.6, label: ""),
      Tick(value:0.7, label: ""),
      Tick(value:0.8, label: "80"),
      Tick(value:0.9, label: ""),
      Tick(value:1.0, label: "100"),
      Tick(value:1.1, label: ""),
      Tick(value:1.2, label: "120"),
    ]
)

let swrStyle = IndicatorStyle(
  width: 160,
  height: 10,
  isFlipped: false,
  min: 1.0,
  max: 3.0,
  warningLevel: 2.5,
  criticalLevel: 2.5,
  ticks:
    [
      Tick(value:1.0, label: "1"),
      Tick(value:1.25, label: ""),
      Tick(value:1.5, label: "1.5"),
      Tick(value:1.75, label: ""),
      Tick(value:2.0, label: "SWR"),
      Tick(value:2.25, label: ""),
      Tick(value:2.5, label: "2.5"),
      Tick(value:2.75, label: ""),
      Tick(value:3.0, label: "3"),
    ]
)

// ----------------------------------------------------------------------------
// MARK: - Views

public struct LevelIndicatorView: View {
  var level: CGFloat
  var style: IndicatorStyle
  
  public init(
    level: CGFloat,
    style: IndicatorStyle
  )
  {
    self.level = min(level , style.max)   // min...max
    self.style = style

    self.style.warningLevel = (style.min...style.max).contains(style.warningLevel) ? style.warningLevel : style.max
    self.style.criticalLevel = (style.warningLevel...style.max).contains(style.criticalLevel) ? style.criticalLevel : style.max
  }
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 1) {
      LegendView(style: style)
      ZStack(alignment: .leading) {
        BarView(level: level, style: style)
        OutlineView(style: style)
        TickView(style: style)
      }
      .rotationEffect(.degrees(style.isFlipped ? 180 : 0))
    }
  }
}

struct LegendView: View {
  var style: IndicatorStyle
  
//  func offset(_ position: CGFloat, _ style: IndicatorStyle) -> CGFloat {
//    if style.isFlipped {
//      return ((1.0 - position) * style.width) - 13.0/2.0
//    } else {
//      guard position != 0 else { return 0 }
//      return (position * style.width) - 13.0/2.0
//    }
//  }
  
  var body: some View {
        
    ZStack(alignment: .leading) {
      ForEach(style.ticks, id:\.value) { tick in
        let tickLocation = (tick.value - style.min) * ((style.width) / (style.max - style.min))
        Text(tick.label).font(style.legendFont)
          .frame(alignment: .leading)
          .offset(x: style.isFlipped ? style.max - tickLocation : tickLocation - (13.0/2.0))
      }
    }
    .frame(width: style.width, height: style.height, alignment: .leading)
    .padding(.horizontal, 10)
  }
}

struct BarView: View {
  var level: CGFloat
  var style: IndicatorStyle
  
  var body: some View {
    let segment0 = level > style.warningLevel ? style.warningLevel : level - style.min
    let segment1 = level > style.warningLevel ? min(level - style.warningLevel, style.criticalLevel - style.warningLevel) : 0
    let segment2 = level > style.criticalLevel ? level - style.criticalLevel : 0
    
    HStack(spacing: 0) {
      Rectangle()
        .frame(width: (segment0 * ((style.width) / (style.max - style.min))), height:style.height)
        .foregroundColor(style.normalColor)
      Rectangle()
        .frame(width: (segment1 * ((style.width) / (style.max - style.min))), height: style.height)
        .foregroundColor(style.warningColor)
      Rectangle()
        .frame(width: min(segment2 * ((style.width) / (style.max - style.min)), style.width * style.criticalLevel), height:style.height)
        .foregroundColor(style.criticalColor)
    }
    .padding(.horizontal, 10)
  }
}

struct TickView: View {
  var style: IndicatorStyle

  var body: some View {
    
    Path { path in
      for tick in style.ticks {
        let tickLocation = (tick.value - style.min) * ((style.width) / (style.max - style.min))
        path.move(to: CGPoint(x: tickLocation , y: 0))
        path.addLine(to: CGPoint(x: tickLocation, y: style.height))
      }
    }
    .stroke(style.tickColor)
    .frame(width: style.width, height: style.height)
    .padding(.horizontal, 10)
  }
}

struct OutlineView: View {
  var style: IndicatorStyle
  
  var body: some View {
    
    Rectangle()
      .frame(width: style.width, height: style.height)
      .foregroundColor(style.backgroundColor)
      .border(style.borderColor)
      .padding(.horizontal, 10)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Previews

struct LevelIndicatorView_Previews: PreviewProvider {
  static var previews: some View {
    LevelIndicatorView(level: 1.1, style: rfPowerStyle)
    LevelIndicatorView(level: 2.0, style: swrStyle)
  }
}

struct LegendView_Previews: PreviewProvider {
  static var previews: some View {
    LegendView(style: rfPowerStyle)
    LegendView(style: swrStyle)
  }
}

struct BarView_Previews: PreviewProvider {
  static var previews: some View {
    BarView(level: 1.1, style: rfPowerStyle)
    BarView(level: 2.0, style: swrStyle)
  }
}

struct TickView_Previews: PreviewProvider {
  static var previews: some View {
    TickView(style: rfPowerStyle)
    TickView(style: swrStyle)  }
}

struct OutlineView_Previews: PreviewProvider {
  static var previews: some View {
    OutlineView(style: rfPowerStyle)
    OutlineView(style: swrStyle)  }
}
