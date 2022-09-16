---
title: "Selecting the right data structure"
categories: Swift
---

I believe that one of the essential skills of software engineer is to select or design proper data structure. In swift, there are many options that we can build on, such as *struct*, *class*, *enum* or *typealias*. But the selection is not always no-brainer and it's good to know all the limitations and possibilities they offer.

But first, this is the situation that we're about to implement. There's an external source providing us with some **Double** value, for example temperature in Celsia unit. In app however, we don't want to show the exact value to user. Instead we want to filter the temperature by given ranges and only show the category. Also, a specific category may have slightly different behaviour (e.g. different text color). And we need to preserve the exact value as it may be needed anytime later.

As the assignment is clear, we can now move on to the funny part - coding.

# Typealias

*Typealias* allows us to declare new type only by reusing the existing ones. It's usefull when it comes to protocol with associated value, protocol composition or when you have a complex type (e.g. closure) that repeats all over the place. It can also improve a code readability.

We can declare new typealias for temperature reusing **Double** type. In your model, you can then have a property of type **Temperature**. For categories, we can define an *enum* that will be returned from an *extension* on new **Temperature** type.

```swift
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
```

This is very simple implementation with straightforward usage as well.

```swift
let temperature: Temperature = 34.5
print(temperature.level?.title)
```

Even though it works, there is a major downside here. We are not guaranteed for **Temperature** type and its *extension* to not be missued out of context. For example, the extension property is available on all **Double** values. This is fine if the development is and always will be done by single person. Once there are more developers in the team, everyone must be aware when to use the extension.

Moreover, it allows us to create a temperature out of defined ranges. We could create a failable initializer for **Temperature** type, but it would still be technically possible to initilize it directly with any value.

```swift
let otherValue: Double = 1.0
print(otherValue.level?.title)

let outOfRangeTemperature: Temperature = 56.7
```

For me personally, I just like when such situations are not even possible, or trigger a compilation warning/error. Let's explore other options we have then.

# Enum

When speaking of categories that are known at implementation time, one can think of *enum*. It defines finite group of related values and also comes with type safety which we are looking for.

As *enum* can't contain any stored value to preserve the exact temperature, we need to use its associated value on each case. We can even comply to **RawRepresentable** to read that associated value more easily and to filter values out of range by failing the initializer.

```swift
enum Temperature: RawRepresentable {
    case low(Double)
    case normal(Double)
    case high(Double)

    var levelTitle: String {
        switch self {
        case .low: return "low"
        case .normal: return "normal"
        case .high: return "high"
        }
    }

    // RawRepresentable
    init?(rawValue: Double) {
        switch rawValue {
        case 0..<30: self = .low(rawValue)
        case 30..<40: self = .normal(rawValue)
        case 40..<50: self = .high(rawValue)
        default: return nil
        }
    }

    var rawValue: Double {
        switch self {
        case let .low(value), let .normal(value), let .high(value):
            return value
        }
    }
}
```

This time we are guaranteed that our code can't be accidentaly called out of context. Implementation seems to be quite easy as well, despite the requirement to have that associated value duplicated on all cases. Usage is also pretty straightforward.

```swift
let temperature: Temperature? = .init(rawValue: 34.5)
print(temperature?.levelTitle)
```

On the other hand, we are now able to instantiate any case directly while providing an out of range value. Another downside is that swift conditions on *enum* with associated value have different syntax. This is no logical issue and can be solved by switch statement, unless we want to check for the specific case only.

```swift
let incorrectTemperature = Temperature.low(56.7)

if let temperature = temperature, case .low = temperature {
    print("Temperature is low: \(temperature.rawValue)")
}
```

In the end, *enum* solves the issue with type safety, but introduces potential inconsistency and the issue with temperature out of range still persists. Luckily, there's still one more option to explore.

# Struct

Another way is to encapsulate all the information in a *struct*. *Struct* is a heterogenous data type that can contain various properties and methods. If you're already familiar with *struct*, this may feel like a step back, but the trick is that we will make it act like an *enum* actually.

```swift
struct Temperature: CaseIterable, RawRepresentable, Equatable {
    let rawValue: Double
    let levelTitle: String

    private let range: Range<Double>

    static let low: Temperature = .init(range: 0..<30, title: "low")
    static let normal: Temperature = .init(range: 30..<40, title: "normal")
    static let high: Temperature = .init(range: 40..<50, title: "high")

    init(range: Range<Double>, title: String) {
        self.rawValue = range.lowerBound
        self.levelTitle = title
        self.range = range
    }

    // CaseIterable
    private(set) static var allCases: [Temperature] = [low, normal, high]

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
```

Each temperature category can be defined as static property using the special **init** method taking a range and title. All of these are grouped in **allCases** static property that is used in constructor to filter out values out of defined ranges. With such implementation the usage is exactly the same as with *enum*.

```swift
let temperature: Temperature? = .init(value: 34.5)
print(temperature?.levelTitle)
```

By providing custom **Equatable** implementation that only compares **levelTitle** value (that is unique per range) we can now have simple conditional statements as we intended.

```swift
if let temperature = temperature, temperature == .low {
    print("Temperature is low: \(temperature.rawValue)")
}
```

We are also guaranteed that we can't create inconsistent ***Temperature*** instance just like in case of *enum*.

# Struct extensibility

There's one more benefit that is not possible with *enum*. We could potentially add more temperature categories in *extension*. For that to work, we would need to come up with some kind of registration mechanism to propagate these new categories to **init** method that would fail otherwise.

```swift
extension Temperature {
    static let extraHigh: Temperature = .init(range: 50..<60, levelTitle: "extra high")

    // Register
    static func registerNewCategory(_ category: Temperature) {
        guard !allCases.contains(category) else { return }
        allCases.append(category)
    }
}
```

To use new category, we need to register it first. Following code snippet then prints title for the newly added category - extra high.

```swift
Temperature.registerNewCategory(.extraHigh)

let temperatureExtraHigh: Temperature? = .init(value: 56.7)
print(temperatureExtraHigh?.levelTitle)
```

This may come handy in modularized application when we need to extend the basic functionality with new value that does not make sense outside of current module. Another usecase may be in a framework to allow for a customization.

# Summary

We tried several basic data structures available in swift to implement relatively simple example and showcased that some of them can even be used in different way that we're used to. 

Even though some of the demonstrated solutions come with few issues, every one of them can do the job. In the end, there is no single solution that you should use every single time. It's up to a developer to know the language possibilities and to select one that fits best for the specific need.

All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/swift/data_structure). Note that you need to comment out other marked cases for the file to be compiled with no error.