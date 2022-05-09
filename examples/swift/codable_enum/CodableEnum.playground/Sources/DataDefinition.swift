import Foundation

// Global values
let json = """
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
"""
let jsonData = json.data(using: .utf8)!

// Model definition
public enum StringEnum: String, Codable {
    case value1
    case value2
}

public enum DecodeError: Error {
    case incorrectValue
}

public protocol Example {
    func run()
}

public class ExampleImpl<T: Decodable>: Example {
    let type: T.Type

    public init(_ type: T.Type) {
        self.type = type
    }

    public func run() {
        print(String(describing: self))
        do {
            let result = try JSONDecoder().decode(type, from: jsonData)
            dump(result)
            print()
        } catch {
            print(error.localizedDescription)
        }
    }
}
