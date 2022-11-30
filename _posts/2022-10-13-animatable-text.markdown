---
title: "Animatable Text"
categories: SwiftUI
---

Animation is an important part of mobile application nowadays as it improves user experience. The truth is that they are not that difficult usually either as basic UI components come with an animation support, at least to some extent. We can get for free component repositioning, size changes or simple opacity animation. With little effort we can also easily get a transition animation towards any screen edge for example.

Yet, sometimes we strive for more complex animation that is not supported out of the box. Fortunately, there is quite a simple way how to achieve them. As one might expect in swift, there's a protocol just to implement.

# Default Text animation

Before we even begin with animation itself, let's see the default behaviour of *Text* component. Below is the code we'll be using for this entire example. Interesting thing is that it's not going to change any further, except for the *Text* component replacement but we'll get to that later.

```swift
struct ContentView: View {
    @State var value: Int = 1

    var body: some View {
        Text("\(value)")
            .frame(width: 150, height: 150)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    value = .random(in: 1...5000)
                }
            }
    }
}
```

When you run the above code, this is the result you'll get. Integer value changes on each component tap.

![Final tag component layout example](/assets/images/text_animation_default.gif)  
*Default text component animation*

But the animation is not that great, old value simply fades out and new value fades in simultaneously. Even thought the value animates, it's not much different from not having any animation at all. We can definitely do better given that we only display numeric values.

# Animatable protocol

So we would like to customize the animation between two numeric values in the same text view. There is a protocol that can help us just with that - *Animatable*. It's a simple protocol with one property requirement `var animatableData: Self.AnimatableData`. Notice of the generic type that allows you to animate changes of any value conforming to *VectorArithmetic* protocol (by default they're *Double*, *Float* and *CGFloat*).

As we intend to display integer values only and *Int* type does not conform to *VectorArithmetic* by default, we have two options here. Either to conform to that protocol ourselves (through extension) or to convert the data internally to one of those supported data types. Both options work the same so in this example we'll go with the second approach.

# Implementation

All we need to do is to create a custom component wrapping *Text* view, make it conform to *Animatable* protocol and implement animatableData property that just converts our value to *Double*.

```swift
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
```

Running the code above should give you the following animation.

![Final tag component layout example](/assets/images/text_animation_enUS.gif)  
*Customized text component animation*

It may slightly differ for you though, depending on your location. The reason is that now it uses your device locale setting in order to decide number style. This may not be always required behaviour, especially if your app support multiple languages. So we'll try to define our custom formatting style to the numeric value.

# Formatted text

Let's first prepare some utility code that can make our next implementation a lot easier. We'll just need to create *NumberFormatter* instance with explicitly defined locale to override system locale and hardcoded numberStyle. Feel free to change numberStyle in your code as needed, could be also passed as parameter.

```swift
extension NumberFormatter {
    convenience init(locale: Locale) {
        self.init()
        self.locale = locale
        self.numberStyle = .decimal
    }
}
```

So next we'll create a new View component *FormattedNumberText* that will implement Animatable protocol the same way as *NumberText* did. Plus we put a number formatter in place. This is the implementation we might end up with.

```swift
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
        Text(NSNumber(integerLiteral: value), formatter: formatter)
    }
}
```

You can now use this new component in the original ContentView code by replacing `Text("\(value)")` with `FormattedNumberText(value: value)`. By doing so, we'll still get the same result as we did previously.

However, we can now also pass locale value to override default number style. For example, if your locale is _en\_US_, then a value of 1000 will be formatted as `1,000`. The same value for locale _cs\_CZ_ is displayed as `1 000`. You can see yourself by passing the locale of your choice here.

```swift
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
```

And that's it. You're now able to override number formatting style by using proper *Locale* instance for your users. And the final animation still works the same.

![Final tag component layout example](/assets/images/text_animation_csCZ.gif)  
*Customized text component animation with custom Locale*

# Summary

SwiftUI is quite capable of providing simple animation for basic components, however they're not always what one might hope for. For those cases, there is *Animatable* protocol to the rescue. By implementing single variable we can help SwiftUI to behave the way we'd like to.

I'm sure that you'll find yourself pretty soon how easy it can be once you'll try one or two implementations. And the final impact on user experience is definitely worth it.

All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/swiftui/animatable_text).