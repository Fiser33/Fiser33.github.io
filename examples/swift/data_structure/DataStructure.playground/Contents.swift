import Foundation


// MARK: - Typealias
typealias Temperature = Double

enum TemperatureLevel: String {
    case low
    case normal
    case high

    var title: String {
        rawValue
    }
}

extension Temperature {
    var level: TemperatureLevel? {
        switch self {
        case 0..<30: return .low
        case 30..<40: return .normal
        case 40..<50: return .high
        default: return nil
        }
    }
}

let temperature: Temperature = 34.5
print(temperature.level?.title)

let otherValue: Double = 1.0
print(otherValue.level?.title)                    // no guarantee that our code is not used out of other context

let outOfRangeTemperature: Temperature = 56.7     // we are able to create temperature out of defined ranges


// MARK: - Enum
enum Temperature: RawRepresentable {
    case low(Double)
    case normal(Double)
    case high(Double)

    init?(value: Double) {
        switch value {
        case 0..<30: self = .low(value)
        case 30..<40: self = .normal(value)
        case 40..<50: self = .high(value)
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .low: return "low"
        case .normal: return "normal"
        case .high: return "high"
        }
    }

    // RawRepresentable
    init?(rawValue: Double) {
        self.init(value: rawValue)
    }

    var rawValue: Double {
        switch self {
        case let .low(value), let .normal(value), let .high(value):
            return value
        }
    }
}

let temperature: Temperature? = .init(value: 34.5)
print(temperature?.title)

let incorrectTemperature = Temperature.low(56.7)              // we are able to create temperature out of defined ranges

if let temperature = temperature, case .low = temperature {
    print("Temperature is low: \(temperature.rawValue)")      // conditional statements need to consider associated values
}


// MARK: - Struct
struct Temperature: Equatable, RawRepresentable, CaseIterable {
    let rawValue: Double
    let levelTitle: String

    private let range: Range<Double>

    static let low: Temperature = .init(range: 0..<30, levelTitle: "low")
    static let normal: Temperature = .init(range: 30..<40, levelTitle: "normal")
    static let high: Temperature = .init(range: 40..<50, levelTitle: "high")

    private(set) static var allCases: [Temperature] = [low, normal, high]

    private init(range: Range<Double>, levelTitle: String) {
        self.rawValue = range.lowerBound
        self.levelTitle = levelTitle
        self.range = range
    }

    // RawRepresentable
    init?(rawValue: Double) {
        guard let level = Self.allCases.first(where: { $0.range.contains(rawValue) }) else {
            return nil
        }
        self.rawValue = rawValue
        self.levelTitle = level.levelTitle
        self.range = level.range
    }

    // Equatable
    static func == (lhs: Temperature, rhs: Temperature) -> Bool {
        lhs.levelTitle == rhs.levelTitle
    }
}

let temperature: Temperature? = .init(rawValue: 34.5)
print(temperature?.levelTitle)

if let temperature = temperature, temperature == .low {
    print("Temperature is low: \(temperature.rawValue)")
}

// MARK: - Struct Extension
extension Temperature {
    static let extraHigh: Temperature = .init(range: 50..<60, levelTitle: "extra high")

    // Register
    static func registerNewCategory(_ category: Temperature) {
        guard !allCases.contains(category) else { return }
        allCases.append(category)
    }
}

Temperature.registerNewCategory(.extraHigh)
let temperatureExtraHigh: Temperature? = .init(rawValue: 56.7)
print(temperatureExtraHigh?.levelTitle)                         // prints newly registered category title
