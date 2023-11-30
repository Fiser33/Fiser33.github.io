---
title: "Swift Macro impression"
categories: Swift
---

# Intro
On the latest Worldwide Developer Conference (WWDC 2023), Apple has introduced a new way on how to extend your source code using **Swift Macro**. It acts like a custom plugin to the Swift compiler that allows you to introduce additional checks or code generation. Code modification and deletion is not allowed. Nevertheless it will be a useful way to reduce repetitive tasks or easily solve tasks that were hard or impossible to achieve previously.

Here I would like to provide my personal impressions from my recent first Swift Macro experience. So brave yourself for plenty of subjective opinions.

# Issues
The main limitation will be requirement of Xcode 15 version so make sure it already runs on your CI/CD machine. Other than that Macro will work on projects targeting most of older OS versions too, the minimum supported versions come from the dependency on `SwiftSyntaxMacros` package, see [Package.swift](https://github.com/apple/swift-syntax/blob/main/Package.swift) definition.

Since Swift Macro is relatively new to the Apple development, you can’t be surprised when there are some limitations or issues. One of the most noticeable issues is the build compilation time significant increase. I won’t get into much details as there is entire [forum thread](https://forums.swift.org/t/macro-adoption-concerns-around-swiftsyntax/66588) on this that will for sure bring more clarity. And from my experience, Apple sillicon does not resolve the issue as you might expect. While increased build time may not be a blocker, it is something to keep in mind because every minute counts today, especially if it costs you money!

Another issue I have encountered was that Xcode build froze to me from time to time. Unfortunately I did not find exact cause to this to know if the issue may still be present in these days. It was most probably a mistake on my end, however it would be nice to have at least some error message, right?

There’s also an inconvenient limitation that it’s not possible to debug using breakpoints in Xcode during the development. The only way seems to be using unit tests. So you will either have to go with Test Driven Development approach or your only other option probably are diagnostic logs which may not be as ideal and definitely more time consuming.

# Resources
The one thing that surprised me though was the documentation. It’s not that there is too few of it. On contrary you’ll find plenty of articles, manuals and even examples out there. It’s just that the existing documentation is not as detailed as one would need or expect.

Of cource there is [the official documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/) from Apple but I was personaly missing some examples to each Macro type to catch the key differences easier. For example it took me some time to figure out what exact Macro kind will be the best fit for my case.

When the official documentation does not suffice or you don’t preferr written text, one can check several sessions on the subject from WWDC 2023, for example [Write Swift macros](https://developer.apple.com/videos/play/wwdc2023/10166/) and other related videos. Unfortunately they still not contain the level of details one may need.

What I found quite useful was this [list of public Swift Macro implementations](https://github.com/krzysztofzablocki/Swift-Macros). You can either see if the Macro is already implemented by someone else so you could save your time and easily reuse. If not, it can help to check reference implementation and maybe even to gain some inspiration from there. This helped me a lot to be honest.

Last but not least, I would love to mention online [Swift Abstract Syntax Tree (AST)](https://swift-ast-explorer.com/) explorer. This site is really a life saver as there’s definitely not enough documentation on this subject. Using the online tool is definitely much faster than manually exploring it on the go only by using the logs. Luckily you don’t have to instantiate entire AST for your return values as it can also be converted from raw String.

# Usage
On the other hand Swift Macro may address many issues that we just got used to over the time. The biggest benefit probably is possibility to eliminate boilerplate code that can be generated automatically and to let you focus on implementation that really matters. It can be for example public init synthetizer on structs that is otherwise available only with internal access modifier. This previously required us to explicitly provide and maintain the code.

And there are many more publicly available Swift Macro implementations that might come really handy for you. For example I’ve seen some related to the Codable protocol. Another possible use may be in unit tests to automatically generate tests only by using different set of input values. Feel free to do your own research based on your actual needs.

In my case I was trying to implement a custom annotation on Combine Subject property that would automatically add more code in order to implement "lazy load" mechanism with option to handle retries and propagate potential errors to the consumer side.

# Summary
Just to remind you, all the above are only my personal impressions after the recent first take on custom Swift Macro implementation. As the feature is still relatively new, we may see many improvements or changes over the next few versions.

As I have mentioned several issues or limitations, there are also plenty of benefits. So please don’t take it like you should not use Swift Macro at all for now. You should evaluate all the benefits and risks specifically for your project as with any new feature or technology.