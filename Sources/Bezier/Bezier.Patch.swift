extension Bezier {
    public struct Patch {
        public let rows: [Bezier<Point>]

        public init(rows: [Bezier<Point>]) throws(Bezier<Point>.Error) {
            guard let first = rows.first else { throw .empty }
            guard rows.allSatisfy({ $0.degree == first.degree }) else { throw .ragged }
            self.rows = rows
        }
    }
}

extension Bezier.Patch {
    public var degree: (u: Int, v: Int) { (rows[0].degree, rows.endIndex - 1) }
    public var columns: [Bezier<Point>] {
        (0...degree.u).map { index in Bezier(nonempty: rows.map { $0.controlPoints[index] }) }
    }
    public var transposed: Self { Self(rectangular: columns) }

    public func map<Result, Failure: Swift::Error>(
        _ transform: (Point) throws(Failure) -> Result
    ) throws(Failure) -> Bezier<Result>.Patch {
        var result: [Bezier<Result>] = []
        result.reserveCapacity(rows.count)
        for row in rows { result.append(try row.map(transform)) }
        return Bezier<Result>.Patch(rectangular: result)
    }

    public func row<Parameter, Failure: Swift::Error>(
        at v: Parameter,
        interpolating interpolate: (Point, Point, Parameter) throws(Failure) -> Point
    ) throws(Failure) -> Bezier<Point> {
        var points: [Point] = []
        points.reserveCapacity(degree.u + 1)
        for column in columns { points.append(try column.value(at: v, interpolating: interpolate)) }
        return Bezier(nonempty: points)
    }

    public func column<Parameter, Failure: Swift::Error>(
        at u: Parameter,
        interpolating interpolate: (Point, Point, Parameter) throws(Failure) -> Point
    ) throws(Failure) -> Bezier<Point> {
        var points: [Point] = []
        points.reserveCapacity(rows.count)
        for row in rows { points.append(try row.value(at: u, interpolating: interpolate)) }
        return Bezier(nonempty: points)
    }

    public func value<Parameter, Failure: Swift::Error>(
        at u: Parameter,
        _ v: Parameter,
        interpolating interpolate: (Point, Point, Parameter) throws(Failure) -> Point
    ) throws(Failure) -> Point {
        try column(at: u, interpolating: interpolate).value(at: v, interpolating: interpolate)
    }
}

extension Bezier.Patch: Equatable where Point: Equatable {}
extension Bezier.Patch: Hashable where Point: Hashable {}
extension Bezier.Patch: Sendable where Point: Sendable {}

extension Bezier.Patch {
    public init(controlPoints: [[Point]]) throws(Bezier<Point>.Error) {
        var rows: [Bezier<Point>] = []
        rows.reserveCapacity(controlPoints.count)
        for row in controlPoints { rows.append(try Bezier(controlPoints: row)) }
        try self.init(rows: rows)
    }

    internal init(rectangular rows: [Bezier<Point>]) { self.rows = rows }
}

#if !hasFeature(Embedded)
    extension Bezier.Patch: Encodable where Point: Encodable {
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rows)
        }
    }

    extension Bezier.Patch: Decodable where Point: Decodable {
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rows = try container.decode([Bezier<Point>].self)
            do {
                try self.init(rows: rows)
            } catch {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "A Bezier patch requires at least one row and rows of one degree"
                )
            }
        }
    }
#endif
