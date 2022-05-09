import Foundation

public class ExampleComputedProperties: ExampleImpl<ExampleComputedProperties.CodableStruct> {
    public init() {
        super.init(CodableStruct.self)
    }

    public struct CodableStruct: Decodable {
        let keyString: String?
        let keyInt: Int?
        let keyArray: [InnerCodableStruct]?

        var keyStringEnum: StringEnum? {
            guard let rawValue = keyString else { return nil }
            return StringEnum(rawValue: rawValue)
        }

        struct InnerCodableStruct: Decodable {
            let otherKey: String?

            var otherKeyEnum: StringEnum? {
              guard let rawValue = otherKey else { return nil }
              return StringEnum(rawValue: rawValue)
            }
        }
    }
}
