---
title: "Codable Enum"
categories: Swift
---

Json (de)serialization is the fundamental skill that every app developer should have. It's commonly used for app configuration, local caching or communication with server. Since introduction of Codable protocol in Swift 4, it became so much easier. But as simple as it could be, there may be some tricky aspects that you are not aware of. I'll try to look at one of them little bit closer today.

For the sake of simplicity, we'll be using Decodable protocol only, which is used for conversion from JSON to out model. For the opposite process, you use Encodable protocol but we won't cover that here today.

# Data definition

Let's first define very simple JSON data that we will try to decode. It contains simple String and Int values and an array of inner structure.

```swift
{
  "keyString": "value1",
  "keyInt": null,
  "keyArray": [
    {
      "otherKey": "value2"
    },
    {
      "otherKey": "value3"
    }
  ]
}
```

You can notice that Int value is missing, but we will focus mainly on String values as our goal will be to use enums to decode them. Let's define the enum we'll be using in code examples:

```swift
enum StringEnum: String, Decodable {
  case value1
  case value2
}
```

# Basic data types and optionals

At first, let's just make decoding working with basic data types, eg. String and Int. That way we'll be sure our code is working and we can start with enhancements. The structure can look like this:

```swift
struct CodableStruct: Decodable {
  let keyString: String
  let keyInt: Int
  let keyArray: [InnerCodableStruct]

  struct InnerCodableStruct: Decodable {
    let otherKey: String
  }
}
```

Assuming we have already stored the JSON string in variable named `json`, this is the code we can use to validate the decoding process.

```swift
let jsonData = json.data(using: .utf8)!
do {
    let result = try JSONDecoder().decode(CodableStruct.self, from: jsonData)
    dump(result)
} catch {
    print(error.localizedDescription)
}
```

When you run the code, you'll get an error message. That's because there is a missing value for `keyInt` in JSON we defined. You can notice entire decoding failed due to this single missing value. That is why it's always for the best to have all fields optional, even if they're supposed to be required. So let's apply that to our structure and see decoding result succeeds.

```swift
struct CodableStruct: Decodable {
  let keyString: String?
  let keyInt: Int?
  let keyArray: [InnerCodableStruct]?

  struct InnerCodableStruct: Decodable {
    let otherKey: String?
  }
}
```

# Enum

Now, since basic decoding works, we can replace String properties for enum.

```swift
struct CodableStruct: Decodable {
  let keyString: StringEnum?
  let keyInt: Int?
  let keyArray: [InnerCodableStruct]?

  struct InnerCodableStruct: Decodable {
    let otherKey: StringEnum?
  }
}
```

Decoding now fails again. The reason is that JSON contains `value3` in one of inner objects, which is not defined by enum. Again, single error fails entire decoding, no matter on what hierarchy level it occurrs. And notice we even defined `otherKey` as optional but to no rescue.

It would be ideal to just ommit those failing elements from array, or to replace them with nil value. So what options do we have?

# Conversion in computed properties

One might think of simply just storing the basic data types and do the conversion somewhere else, for example in computed properties on model itself. 

```swift
struct CodableStruct: Decodable {
  let keyString: String?
  let keyInt: Int?
  let keyArray: [InnerCodableStruct]?

  var keyStringEnum: StringEnum? {
    guard let rawValue = keyString else { return nil }
    return StringEnum(rawValue: rawValue)
  }

  struct InnerCodableStruct: Decodable {
    let otherKey: StringEnum?
  }
}
```

Even though this solution seems simple and straightforward, it also introduces more demand on using this model. For example, you do have to know which property of the two (one of basic data type and another one of enum type) to access. Not even speaking of need to handle optionals all over your code base, like using guard statements or nil coalescing operator.

# Custom Decodable implementation

Another option is to work more with Decodable protocol. When we use Codable, we get synthesized implementation of required methods (under certain circumstances). We can also provide our custom implementation for those if needed. Which is the way we'll improve our code now.

To provide custom methods implementation, we need to implement custom CodingKey and provide custom implementation of one and only Decodable protocol method.

```swift
struct CodableStruct: Decodable {
  ...

  enum CodingKeys: String, CodingKey {
    case keyString
    case keyInt
    case keyArray
  }

  init(from decoder: Decoder) throws {
    // 1
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // 2
    self.keyInt = try? container.decode(Int.self, forKey: .keyInt)

    // 3
    let keyString = try? container.decode(String.self, forKey: .keyString)
    self.keyString = StringEnum(rawValue: keyString ?? "")

    // 4
    var nestedContainer = try container.nestedUnkeyedContainer(forKey: CodingKeys.keyArray)
    var innerArray: [InnerCodableStruct] = []
    while !nestedContainer.isAtEnd {
      do {
        // 5
        let value = try nestedContainer.decode(InnerCodableStruct.self)
        innerArray.append(value)
      } catch {
        // 6
        try? nestedContainer.superDecoder().singleValueContainer()
      }
    }
    keyArray = innerArray
  }
}
```

This is what's happening there:
1. We retrieve container for the values accessible by our CodingKey implementation.
2. Decode simple optional Int value.
3. Decode raw value for enum first and then try to convert to enum. As the property is optional, result value can be nil.
4. For array values, we need to get nested container. In while cycle, we check there are still some values left to process.
5. Try to decode single structure and eventually store in local array for later use.
6. If decoding fails for any reason, this ensures container skips the faulty element, otherwise you would check same element again and end up with infinite loop.

To make the implementation complete, we need to do the same for all structures used in the hierarchy which is, in this example, just Inner structure. For decoding of the enum, we'll require the value in init method in order to raise an error in previous decoding example, so the element is omitted in the resulting array.

```swift
struct InnerCodableStruct: Decodable {
  ...

  enum CodingKeys: String, CodingKey {
    case otherKey
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let keyString = try container.decode(String.self, forKey: .otherKey)
    guard let keyEnum = StringEnum(rawValue: keyString) else { 
      // 1
      throw DecodeError.incorrectValue 
    }
    // 2
    self.otherKey = keyEnum
  }
}
```

1. Check and eventually throw an error if conversion to enum fails.
2. Store converted value if everything succeeds.

Decoding now succeeds and the failing element is simply just ommited. Just as we wanted. The downside of this approach is it contains too much boilerplate code, just imagine applying this approach in larger code base with tens of structures.

# Property wrappers

Luckily for us, there are ways to deal with this boilerplate code in Swift. One possibility is to use Property wrappers to wrap the decoding logic. For simplicity, let's define two property wrappers - one for conversion to enum and another one for decoding of array.

```swift
@propertyWrapper struct Serialized<T: Decodable>: Decodable {
  var wrappedValue: T!

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.wrappedValue = try container.decode(T.self)
  }
}

@propertyWrapper struct SerializedArray<T: Decodable>: Decodable {
  var wrappedValue: [T] = []

  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()

    var array: [T] = []
    while !container.isAtEnd {
      do {
        let value = try container.decode(T.self)
        array.append(value)
      } catch {
        _ = try? container.superDecoder().singleValueContainer()
      }
    }
    self.wrappedValue = array
  }
}
```

With these two property wrappers defined, we can update our decoding structure as follows:

```swift
struct CodableStruct: Decodable {
  let keyInt: Int?
  
  @Serialized
  var keyString: StringEnum?
  
  @SerializedArray
  var keyArray: [InnerCodableStruct]?

  struct InnerCodableStruct: Decodable {
    @Serialized
    var otherKey: StringEnum?
  }
}
```

With all properties still conforming to Decodable protocol, we don't need to define custom init implementation while still having the logic for enum conversion and skipping faulty elements from array.

# Conclusion

We looked on such a basic task of JSON deserialization but as basic as it is, it could be really tricky when we try to use it in conjuction with enums. I introduced you some possible improvements that we can implement in Swift, but each of them have pros and cons to consider. 

First solution is to create computed properties for all enum fields and do the conversion manually there. Downside is that you may end up with twice as much properties as your model and all of these are optional, unless you provide a default value. You also have to use these computed properties in all your codebase and handle optionals. Upside is that amount of code in model itself is pretty low.

Another solution is to provide custom implementation of protocol method. Even though there is lot of boilerplate code, the logic is still encapsulated in model and you can handle optionals much better. And there is also a solution for the boilerplate code issue.

Both options can be viable to use, the only key aspect always is what fits best for you and your project.

All code is available in the [repository](https://github.com/Fiser33/Fiser33.github.io/tree/main/examples/swift/codable_enum).