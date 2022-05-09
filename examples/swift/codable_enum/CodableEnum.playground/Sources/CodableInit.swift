import Foundation

public class ExampleCodableInit: ExampleImpl<ExampleCodableInit.CodableStruct> {
    public init() {
        super.init(CodableStruct.self)
    }

    public struct CodableStruct: Decodable {
        let keyString: StringEnum?
        let keyInt: Int?
        let keyArray: [InnerCodableStruct]

        enum CodingKeys: String, CodingKey {
            case keyString
            case keyInt
            case keyArray
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let keyStringRaw = try? container.decode(String.self, forKey: .keyString)
            self.keyString = StringEnum(rawValue: keyStringRaw ?? "")
            self.keyInt = try? container.decode(Int.self, forKey: .keyInt)

            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .keyArray)
            var innerArray: [InnerCodableStruct] = []
            while !nestedContainer.isAtEnd {
                do {
                    let value = try nestedContainer.decode(InnerCodableStruct.self)
                    if value.otherKey != nil {
                        innerArray.append(value)
                    }
                } catch {
                    _ = try? nestedContainer.superDecoder().singleValueContainer()
                }
            }
            keyArray = innerArray
        }

        struct InnerCodableStruct: Decodable {
            let otherKey: StringEnum?

            enum CodingKeys: String, CodingKey {
                case otherKey
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                let otherKeyRaw = try? container.decode(String.self, forKey: .otherKey)
                self.otherKey = StringEnum(rawValue: otherKeyRaw ?? "")
            }
        }
    }
}
