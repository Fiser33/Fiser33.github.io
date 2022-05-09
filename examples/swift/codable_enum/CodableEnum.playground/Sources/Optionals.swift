import Foundation

public class ExampleOptionals: ExampleImpl<ExampleOptionals.CodableStruct> {
    public init() {
        super.init(CodableStruct.self)
    }

    public struct CodableStruct: Decodable {
        let keyString: String?
        let keyInt: Int?
        let keyArray: [InnerCodableStruct]?

        struct InnerCodableStruct: Decodable {
            let otherKey: String?
        }
    }
}
