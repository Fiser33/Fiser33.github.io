//: A UIKit based Playground for presenting user interface
  
import SwiftUI
import PlaygroundSupport

// Present the view controller in the Live View window
PlaygroundPage.current.setLiveView(ContentView())

struct ContentView: View {
    @State var value: Int = 1

    var body: some View {
        FormattedNumberText(value: value, locale: Locale(identifier: "cs_CZ"))
            .frame(width: 150, height: 150)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    value = .random(in: 1...5000)
                }
            }
    }
}

extension Int: VectorArithmetic {
    public mutating func scale(by rhs: Double) {
        self = Int(round(Double(self) * rhs))
    }

    public var magnitudeSquared: Double {
        Double(self).magnitudeSquared
    }
}

struct NumberText: View, Animatable {
    var value: Int

    var animatableData: Double {
        get { Double(value) }
        set { value = Int(newValue) }
    }

    var body: some View {
        Text("\(value)")
    }
}

struct FormattedNumberText: View, Animatable {
    var value: Int
    let formatter: NumberFormatter

    static var defaultFormatter = NumberFormatter(locale: .current)

    init(value: Int, formatter: NumberFormatter = Self.defaultFormatter) {
        self.value = value
        self.formatter = formatter
    }

    init(value: Int, locale: Locale) {
        self.value = value
        self.formatter = NumberFormatter(locale: locale)
    }

    var animatableData: Double {
        get { Double(value) }
        set { value = Int(newValue) }
    }
//    var animatableData: Double {
//        get { round(value.doubleValue) }
//        set { value = NSNumber(floatLiteral: round(newValue)) }
//    }

    var body: some View {
        Text(formatter.string(from: NSNumber(integerLiteral: value)) ?? "")
    }
}

//struct FormattedNumberText: View, Animatable {
//    var value: Int
//    let formatter: NumberFormatter
//
//    static var defaultFormatter = NumberFormatter(locale: .current, numberStyle: .decimal)
//
//    init(value: Int, formatter: NumberFormatter = Self.defaultFormatter) {
//        self.value = value
//        self.formatter = formatter
//    }
//
//    init(value: Int, locale: Locale, style: NumberFormatter.Style = Self.defaultFormatter.numberStyle) {
//        self.value = value
//        self.formatter = NumberFormatter(locale: locale, numberStyle: style)
//    }
//
//    var animatableData: Int {
//        get { value }
//        set { value = newValue }
//    }
//
//    var body: some View {
//        Text(NSNumber(integerLiteral: value), formatter: formatter)
//    }
//}

extension NumberFormatter {
    convenience init(locale: Locale) {
        self.init()
        self.locale = locale
        self.numberStyle = .decimal
    }
}
