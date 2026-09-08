#if !hasFeature(Embedded)
extension Bezier: Encodable where Point: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(controlPoints)
    }
}

extension Bezier: Decodable where Point: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let points = try container.decode([Point].self)
        do {
            try self.init(controlPoints: points)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "A Bezier curve requires at least one control point"
            )
        }
    }
}
#endif
