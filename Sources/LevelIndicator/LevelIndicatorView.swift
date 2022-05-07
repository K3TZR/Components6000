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
  public var label: String?
  public var hideLine: Bool

  public init
  (
    value: CGFloat,
    label: String? = nil,
    hideLine: Bool = false
  )
  {
    self.value = value
    self.label = label
    self.hideLine = hideLine
  }
}

public struct IndicatorStyle {
  var width: CGFloat
  var height: CGFloat
  var isFlipped: Bool
  var left: CGFloat
  var right: CGFloat
  var warningLevel: CGFloat
  var criticalLevel: CGFloat
  var backgroundColor: Color
  var normalColor: Color
  var warningColor: Color
  var criticalColor: Color
  var borderColor: Color
  var tickColor: Color
  var legendFont: NSFont
  var legendColor: Color
  var ticks: [Tick]
  
  public init
  (
    width: CGFloat = 220,
    height: CGFloat = 30,
    isFlipped: Bool = false,
    left: CGFloat = 0.0,
    right: CGFloat = 1.0,
    warningLevel: CGFloat = 0.8,
    criticalLevel: CGFloat = 0.9,
    backgroundColor: Color = .clear,
    normalColor: Color = .green,
    warningColor: Color = .yellow,
    criticalColor: Color = .red,
    borderColor: Color = .blue,
    tickColor: Color = .blue,
    legendFont: NSFont = NSFont(name: "Monaco", size: 12)!,
    legendColor: Color = .orange,
    ticks: [Tick] = []
  )
  {
    self.width = width
    self.height = height
    self.isFlipped = isFlipped
    self.left = left
    self.right = right
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

public let rfPowerStyle = IndicatorStyle(
  right: 1.2,
  warningLevel: 1.0,
  criticalLevel: 1.1,
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:0.1),
      Tick(value:0.2),
      Tick(value:0.3),
      Tick(value:0.4, label: "40"),
      Tick(value:0.50),
      Tick(value:0.6, label: "RF Pwr"),
      Tick(value:0.7),
      Tick(value:0.8, label: "80"),
//      Tick(value:0.9),
      Tick(value:1.0, label: "100"),
      Tick(value:1.1),
      Tick(value:1.2, label: "120"),
    ]
)

public let swrStyle = IndicatorStyle(
  left: 1.0,
  right: 3.0,
  warningLevel: 2.0,
  criticalLevel: 2.5,
  ticks:
    [
      Tick(value:1.0, label: "1"),
      Tick(value:1.25),
      Tick(value:1.5, label: "1.5"),
      Tick(value:1.75),
      Tick(value:2.0, label: "SWR"),
      Tick(value:2.25),
      Tick(value:2.5, label: "2.5"),
      Tick(value:2.75),
      Tick(value:3.0, label: "3"),
    ]
)

public let alcStyle = IndicatorStyle(
  warningLevel: 0.25,
  criticalLevel: 0.5,
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:0.20),
      Tick(value:0.4),
      Tick(value:0.5, label: "ALC", hideLine: true),
      Tick(value:0.6),
      Tick(value:0.8),
      Tick(value:1.0, label: "100"),
    ]
)

public let micLevelStyle = IndicatorStyle(
  isFlipped: true,
  left: -40.0,
  right: 5.0,
  warningLevel: -10.0,
  criticalLevel: -20.0,
  ticks:
    [
      Tick(value:5.0),
      Tick(value:0.0, label: "0"),
      Tick(value:-5.0),
      Tick(value:-10.0, label: "-10"),
      Tick(value:-15.0),
      Tick(value:-20.0, label: "Mic Level"),
      Tick(value:-25.0),
      Tick(value:-30.0, label: "-30"),
//      Tick(value:-35.0),
      Tick(value:-40.00, label: "-40"),
    ]
)

public let compressionStyle = IndicatorStyle(
  isFlipped: true,
  left: -25.0,
  right: 0.0,
  warningLevel: -10.0,
  criticalLevel: -20.0,
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:-5.0),
      Tick(value:-10.0),
      Tick(value:-12.5, label: "Compression", hideLine: true),
      Tick(value:-15.0),
//      Tick(value:20.0),
      Tick(value:-25.0, label: "-25"),
    ]
)

// ----------------------------------------------------------------------------
// MARK: - Views

public struct LevelIndicatorView: View {
  var level: CGFloat
  var style: IndicatorStyle
  var negateLevel: Bool = false
  
  public init(
    level: CGFloat,
    style: IndicatorStyle
  )
  {
    self.level = level
    self.style = style
  }
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 0) {
      LegendView(style: style, negateLevel: negateLevel).frame(height: style.height/2.0)
      ZStack(alignment: .bottomLeading) {
        BarView(level: level, style: style)
        OutlineView(style: style)
        TickView(style: style)
      }
      .frame(height: style.height/2.0)
      .clipped()
      .rotationEffect(.degrees(style.isFlipped ? 180 : 0))
    }
    .frame(width: style.width, height: style.height, alignment: .leading)
    .padding(.horizontal, 10)
  }
}

struct LegendView: View {
  var style: IndicatorStyle
  var negateLevel: Bool
  
  func width(_ label: String?) -> CGFloat {
    guard label != nil else { return 0 }
    let font = NSFont(name: "Monaco", size: 12)
    let fontAttributes = [NSAttributedString.Key.font: font]
    let size: CGSize = label!.size(withAttributes: fontAttributes as [NSAttributedString.Key : Any])
    return ceil(size.width) / 2
  }
  
  var body: some View {
        
    ZStack(alignment: .leading) {
      ForEach(style.ticks, id:\.value) { tick in
        let tickLocation = (tick.value - style.left) * ((style.width) / (style.right - style.left))
        Text(tick.label ?? "").font(Font(style.legendFont))
          .frame(alignment: .leading)
          .offset(x: tickLocation  - width(tick.label))
      }
      .foregroundColor(style.legendColor)
    }
  }
}

struct BarView: View {
  var level: CGFloat
  var style: IndicatorStyle
  
  var body: some View {
    let normalPerCent = style.isFlipped ? style.right - style.warningLevel : style.warningLevel - style.left
    let warningPerCent = style.isFlipped ? style.warningLevel - style.criticalLevel : style.criticalLevel - style.warningLevel
    let criticalPerCent = style.isFlipped ? style.criticalLevel - style.left : style.right - style.criticalLevel
    let clipPerCent = style.isFlipped ? style.right - level : level - style.left
    let valueRange = style.right - style.left

    HStack(spacing: 0) {
      Rectangle()
        .fill(style.normalColor)
        .frame(width: (style.width) * (normalPerCent) / valueRange, alignment: .leading)
      Rectangle()
        .fill(style.warningColor)
        .frame(width: (style.width) * (warningPerCent) / valueRange, alignment: .leading)
      Rectangle()
        .fill(style.criticalColor)
        .frame(width: (style.width) * (criticalPerCent) / valueRange, alignment: .leading)
    }
    .frame(width: (style.width) * (clipPerCent) / valueRange, alignment: .leading)
    .clipped()
  }
}

struct TickView: View {
  var style: IndicatorStyle

  var body: some View {
    
    let valueRange = style.right - style.left
    var tickLocation: CGFloat = 0
    
    Path { path in
      for tick in style.ticks {
        if tick.hideLine == false {
          if style.isFlipped {
            tickLocation = ( style.right - tick.value) * ((style.width) / valueRange)
          } else {
            tickLocation = (tick.value - style.left) * ((style.width) / valueRange)
          }
          path.move(to: CGPoint(x: tickLocation , y: style.height))
          path.addLine(to: CGPoint(x: tickLocation, y: 0))
        }
      }
    }
    .stroke(style.tickColor)
  }
}

struct OutlineView: View {
  var style: IndicatorStyle
  
  var body: some View {
    
    Rectangle()
      .foregroundColor(style.backgroundColor)
      .border(style.borderColor)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Previews

struct LevelIndicatorView_Previews: PreviewProvider {
  static var previews: some View {
//    Group {
//      LevelIndicatorView(level: 0.5, style: rfPowerStyle)
//        .previewDisplayName("Rf Power @ 0.5")
//      LevelIndicatorView(level: 1.0, style: rfPowerStyle)
//        .previewDisplayName("Rf Power @ 1.0")
//      LevelIndicatorView(level: 1.1, style: rfPowerStyle)
//        .previewDisplayName("Rf Power @ 1.1")
      LevelIndicatorView(level: 1.2, style: rfPowerStyle)
        .previewDisplayName("Rf Power @ 1.2")
//    }

//    Group {
//      LevelIndicatorView(level: 1.5, style: swrStyle)
//        .previewDisplayName("SWR @ 1.5")
//      LevelIndicatorView(level: 2.0, style: swrStyle)
//        .previewDisplayName("SWR @ 2.0")
//      LevelIndicatorView(level: 2.5, style: swrStyle)
//        .previewDisplayName("SWR @ 2.5")
      LevelIndicatorView(level: 3.0, style: swrStyle)
        .previewDisplayName("SWR @ 3.0")
//    }

//    Group {
//      LevelIndicatorView(level: 0.25, style: alcStyle)
//        .previewDisplayName("ALC @ 0.25")
//      LevelIndicatorView(level: 0.50, style: alcStyle)
//        .previewDisplayName("ALC @ 0.50")
      LevelIndicatorView(level: 1.0, style: alcStyle)
        .previewDisplayName("ALC @ 1.0")
//    }

//    Group {
//      LevelIndicatorView(level: 5.0, style: micLevelStyle)
//        .previewDisplayName("MicLevel @ 5.0")
//      LevelIndicatorView(level: 0.0, style: micLevelStyle)
//        .previewDisplayName("MicLevel @ 0.0")
//      LevelIndicatorView(level: -10.0, style: micLevelStyle)
//        .previewDisplayName("MicLevel @ -10.0")
//      LevelIndicatorView(level: -20.0, style: micLevelStyle)
//        .previewDisplayName("MicLevel @ -20.0")
//      LevelIndicatorView(level: -30.0, style: micLevelStyle)
//        .previewDisplayName("MicLevel @ -30.0")
      LevelIndicatorView(level: -40.0, style: micLevelStyle)
        .previewDisplayName("MicLevel @ -40.0")
//    }

//    Group {
//      LevelIndicatorView(level: 0.0, style: compressionStyle)
//        .previewDisplayName("Compression @ 0.0")
//      LevelIndicatorView(level: -5.0, style: compressionStyle)
//        .previewDisplayName("Compression @ -5.0")
//      LevelIndicatorView(level: -10.0, style: compressionStyle)
//        .previewDisplayName("Compression @ -10.0")
//      LevelIndicatorView(level: -15.0, style: compressionStyle)
//        .previewDisplayName("Compression @ -15.0")
//      LevelIndicatorView(level: -20.0, style: compressionStyle)
//        .previewDisplayName("Compression @ -20.0")
      LevelIndicatorView(level: -25.0, style: compressionStyle)
        .previewDisplayName("Compression @ -25.0")
//    }
  }
}

struct LegendView_Previews: PreviewProvider {
  static var previews: some View {
    LegendView(style: rfPowerStyle, negateLevel: false)
      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("LegendView: Rf Power")
    LegendView(style: swrStyle, negateLevel: false)
      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("LegendView: SWR")
    LegendView(style: alcStyle, negateLevel: false)
      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("LegendView: ALC")
    LegendView(style: micLevelStyle, negateLevel: false)
      .frame(width: micLevelStyle.width, height: micLevelStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("LegendView: Mic")
    LegendView(style: compressionStyle, negateLevel: false)
      .frame(width: compressionStyle.width, height: compressionStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("LegendView: Proc")
  }
}

struct BarView_Previews: PreviewProvider {
  static var previews: some View {
//    BarView(level: 0.5, style: rfPowerStyle, negateLevel: false)
//      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
//      .padding(.horizontal, 10)
//      .previewDisplayName("BarView: Rf Power @ 0.5")
//    BarView(level: 1.0, style: rfPowerStyle, negateLevel: false)
//      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
//      .padding(.horizontal, 10)
//      .previewDisplayName("BarView: Rf Power @ 1.0")
//    BarView(level: 1.1, style: rfPowerStyle, negateLevel: false)
//      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
//      .padding(.horizontal, 10)
//      .previewDisplayName("BarView: Rf Power @ 1.1")
    BarView(level: 1.2, style: rfPowerStyle)
      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("BarView: Rf Power @ 1.2")

    BarView(level: 2.6, style: swrStyle)
      .frame(width: swrStyle.width, height: swrStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("BarView: SWR @ 2.6")

    BarView(level: 0.6, style: alcStyle)
      .frame(width: alcStyle.width, height: alcStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("BarView: ALC @ 0.6")

    BarView(level: 20.0, style: micLevelStyle)
      .frame(width: micLevelStyle.width, height: micLevelStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("BarView: Mic @ 20.0")

    BarView(level: 20.0, style: compressionStyle)
      .frame(width: compressionStyle.width, height: compressionStyle.height, alignment: .leading)
      .padding(.horizontal, 10)
      .previewDisplayName("BarView: Proc @ 20.0")
  }
}

struct TickView_Previews: PreviewProvider {
  static var previews: some View {
    TickView(style: rfPowerStyle)
      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("TickView: Rf Power")

    TickView(style: swrStyle)
      .frame(width: swrStyle.width, height: swrStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("TickView: SWR")

    TickView(style: alcStyle)
      .frame(width: alcStyle.width, height: alcStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("TickView: ALC")

    TickView(style: micLevelStyle)
      .frame(width: micLevelStyle.width, height: micLevelStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("TickView: Mic")

    TickView(style: compressionStyle)
      .frame(width: compressionStyle.width, height: compressionStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("TickView: Proc")
  }
}

struct OutlineView_Previews: PreviewProvider {
  static var previews: some View {
    OutlineView(style: rfPowerStyle)
      .frame(width: rfPowerStyle.width, height: rfPowerStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("OutlineView: Rf Power")

    OutlineView(style: swrStyle)
      .frame(width: swrStyle.width, height: swrStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("OutlineView: SWR")

    OutlineView(style: alcStyle)
      .frame(width: alcStyle.width, height: alcStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("OutlineView: ALC")

    OutlineView(style: micLevelStyle)
      .frame(width: micLevelStyle.width, height: micLevelStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("OutlineView: Mic")

    OutlineView(style: compressionStyle)
      .frame(width: compressionStyle.width, height: compressionStyle.height)
      .padding(.horizontal, 10)
      .previewDisplayName("OutlineView: Proc")
  }
}





extension String {
   func widthOfString(usingFont font: Font) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}
