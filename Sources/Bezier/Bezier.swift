public struct Bezier<Point> {
    public let controlPoints: [Point]

    @inlinable
    public init(controlPoints: [Point]) throws(Error) {
        guard !controlPoints.isEmpty else { throw .empty }
        self.controlPoints = controlPoints
    }
}

extension Bezier {
    @inlinable
    public var degree: Int { controlPoints.count - 1 }
    @inlinable
    public var start: Point { controlPoints[0] }
    @inlinable
    public var end: Point { controlPoints[controlPoints.count - 1] }
    @inlinable
    public var reversed: Self { Self(nonempty: controlPoints.reversed()) }

    @inlinable
    public func map<Result, Failure: Swift::Error>(
        _ transform: (Point) throws(Failure) -> Result
    ) throws(Failure) -> Bezier<Result> {
        var result: [Result] = []
        result.reserveCapacity(controlPoints.count)
        for point in controlPoints { result.append(try transform(point)) }
        return Bezier<Result>(nonempty: result)
    }

    @inlinable
    public func value<Parameter, Failure: Swift::Error>(
        at parameter: Parameter,
        interpolating interpolate: (Point, Point, Parameter) throws(Failure) -> Point
    ) throws(Failure) -> Point {
        var row = controlPoints
        var count = row.count
        while count > 1 {
            for index in 0..<(count - 1) {
                row[index] = try interpolate(row[index], row[index + 1], parameter)
            }
            count -= 1
        }
        return row[0]
    }

    @inlinable
    public func split<Parameter, Failure: Swift::Error>(
        at parameter: Parameter,
        interpolating interpolate: (Point, Point, Parameter) throws(Failure) -> Point
    ) throws(Failure) -> (left: Self, right: Self) {
        var row = controlPoints
        var count = row.count
        var left = [row[0]]
        var right = [row[count - 1]]
        left.reserveCapacity(count)
        right.reserveCapacity(count)
        while count > 1 {
            for index in 0..<(count - 1) {
                row[index] = try interpolate(row[index], row[index + 1], parameter)
            }
            count -= 1
            left.append(row[0])
            right.append(row[count - 1])
        }
        return (Self(nonempty: left), Self(nonempty: right.reversed()))
    }
}

extension Bezier: Equatable where Point: Equatable {}
extension Bezier: Hashable where Point: Hashable {}
extension Bezier: Sendable where Point: Sendable {}

extension Bezier {

    @inlinable
    public init(point: Point) { self.controlPoints = [point] }

    @inlinable
    public init(start: Point, end: Point) {
        self.controlPoints = [start, end]
    }

    @inlinable
    public init(start: Point, control: Point, end: Point) {
        self.controlPoints = [start, control, end]
    }

    @inlinable
    public init(start: Point, control1: Point, control2: Point, end: Point) {
        self.controlPoints = [start, control1, control2, end]
    }

    @usableFromInline
    internal init(nonempty controlPoints: [Point]) { self.controlPoints = controlPoints }
}

#if !hasFeature(Embedded)
    extension Bezier: Encodable where Point: Encodable {
        @inlinable
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(controlPoints)
        }
    }

    extension Bezier: Decodable where Point: Decodable {
        @inlinable
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let points = try container.decode([Point].self)
            do {
                try self.init(controlPoints: points)
            } catch {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "A Bezier curve requires at least one control point"
                )
            }
        }
    }
#endif
