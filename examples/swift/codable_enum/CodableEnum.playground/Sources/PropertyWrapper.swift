import Foundation

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

public class ExamplePropertyWrapper: ExampleImpl<ExamplePropertyWrapper.CodableStruct> {
    public init() {
        super.init(CodableStruct.self)
    }

    public struct CodableStruct: Decodable {
        let keyInt: Int?

        @Serialized
        private(set) var keyString: StringEnum?

        @SerializedArray
        private(set) var keyArray: [InnerCodableStruct]

        struct InnerCodableStruct: Decodable {
            @Serialized
            private(set) var otherKey: StringEnum?
        }
    }
}
