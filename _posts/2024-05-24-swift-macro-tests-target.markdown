---
title: "Run Swift Macro tests on iOS target"
categories: Swift
---

Swift macros, introduced almost a year ago on [**WWDC23**](https://developer.apple.com/videos/play/wwdc2023/10166/), offer powerful capabilities for code generation and transformation. It is very likely that you have implemented some yourself or used a publicly available ones already. We already have 3 of them in place on my work project and we plan to add more.

However, there are still some limitations when it comes to testing these macros in a non-macOS project. In short, your unit tests in macro package may not actually run and therefore bugs can easily squeeze in. I’d like to show you how to make sure they run on all projects regardless the target platform.

# Issue

The issue is visible right from the default Swift Macro template in Xcode (File -> New -> Package -> Swift Macro). When you navigate to generated unit tests file, you’ll see bunch of `#if canImport(...)` conditions everywhere. Additionaly, there is the following line inside of all test methods:

> throw XCTSkip("macros are only supported when running tests for the host platform")

In case your selected run destination is different from _My Mac_ device, all the test code will be dimmed a bit indicating that it will not run.

![Swift Macro tests for iOS target with default configuration](/assets/images/swift_macro_test_before.png)
*Swift Macro tests for iOS target with default configuration*

Having unit tests that do not actually run is useless and may even lead to bugs as developers might be misslead that their changes were tested.

# Reason

The reason is quite obvious from the _XCTSkip_ message itself. Swift Macros are evaluated during the project compilation phase that happens on your macOS device. So for the macro to be available there, it has to be compiled for macOS (the host platform) first. This is possible using the `macro` target in the package definition:

```swift
// Macro implementation that performs the source transformation of a macro.
.macro(
    name: "MacroExampleMacros",
    ...
),

// A test target used to develop the macro implementation.
.testTarget(
    name: "MacroExampleTests",
    dependencies: [
        "MacroExampleMacros",
        ...
    ]
),
```

Such a macro target by default contains all the implementation and results in the code being skipped from testing for non-macOS run destinations.

# Solution

One can say this is not such a big issue and may be solved just by running macro tests on macOS target. While this is definitely true, it also has few drawbacks. First, it implies this knowledge among all team members and relies on them actually running these tests in addition to standard tests. Moreover it is not that simple to automate this check on CI/CD and adds unnecessary complexity when it comes for example to code coverage reporting.

There is a simple solution that does not come with those drawbacks though. All it takes is to slightly modify the macro package structure. You can change the existing `macro` target to be simple target instead. Then add a new `macro` target that will be just bridging to the actual implementation.

```swift
// Macro implementation that performs the source transformation of a macro.
.target(
    name: "MacroExampleMacros",
    ...
),

// Target to bridge actual macro implementation
.macro(
    name: "MacroExampleBridge",
    dependencies: [
        "MacroExampleMacros",
        ...
    ]
),

// A test target used to develop the macro implementation.
.testTarget(
    name: "MacroExampleTests",
    dependencies: [
        "MacroExampleMacros",
        ...
    ]
),
```

In the bridging `macro` target you will need to provide the following implementation for every single macro you have. This will still execute the actual implementation from the other regular target and therefore make it visible for swift compiler. The benefit of having our macro unit tests executed wins very easily over such a little boilerplate in my opinion.

```swift
import MacroExampleMacros

public struct StringifyMacroBridge: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        StringifyMacro.expansion(of: node, in: context)
    }
}
```

Don’t forget to update your main macro _CompilerPlugin_ definition to link against the bridging types instead.

```swift
@main
struct MacroExamplePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacroBridge.self,
    ]
}
```

One last requirement is to update the exposed macro declaration to use the bridging `macro` target now.

```swift
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroExampleBridge", type: "StringifyMacroBridge")
```

When this is done, you should be able to run unit tests of Swift Macro implementation for any supported run destination.

![Swift Macro tests for iOS target after package modification](/assets/images/swift_macro_test_after.png)
*Swift Macro tests for iOS target after package modification*

# Summary

Even though Swift Macros are still not perfect and come with some limitations, there are some easy workarounds to achieve the expected behaviour today.

The presented workaround is not so complicated and has great benefits. First it does not imply much knowledge from team members. When a new team member tries to introduce new macro implementation, they can easily follow the convention from the existing source code and should be able to integrate it on their own. Second your macro implementation will now be tested the same way as other source code, ensuring the behaviour does not change unintentionally.

All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/swift/macro-tests).