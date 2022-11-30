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

    var body: some View {
        Text(formatter.string(from: NSNumber(integerLiteral: value)) ?? "")
    }
}

extension NumberFormatter {
    convenience init(locale: Locale) {
        self.init()
        self.locale = locale
        self.numberStyle = .decimal
    }
}
