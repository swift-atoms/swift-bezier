/// A nonempty ordered control polygon for one polynomial Bézier curve.
///
/// The declared degree is the control-point count minus one, including degree
/// zero. It need not be the minimal degree of the represented curve. Points
/// retain their own domain/frame; no coordinates or metric are required here.
public struct Bezier<Point> {
    public let controlPoints: [Point]

    public enum Error: Swift.Error, Equatable, Sendable {
        case empty
    }

    public init(controlPoints: [Point]) throws(Error) {
        guard !controlPoints.isEmpty else { throw .empty }
        self.controlPoints = controlPoints
    }

    public var degree: Int { controlPoints.count - 1 }
    public var start: Point { controlPoints[0] }
    public var end: Point { controlPoints[controlPoints.count - 1] }
    public var reversed: Self { Self(nonempty: controlPoints.reversed()) }

    /// Map control points, not the entire curve under an arbitrary nonlinear map.
    public func map<Result, Failure: Swift.Error>(
        _ transform: (Point) throws(Failure) -> Result
    ) throws(Failure) -> Bezier<Result> {
        var result: [Result] = []
        result.reserveCapacity(controlPoints.count)
        for point in controlPoints { result.append(try transform(point)) }
        return Bezier<Result>(nonempty: result)
    }

    /// De Casteljau evaluation with explicitly supplied affine interpolation.
    ///
    /// The caller owns parameter validity and interpolation laws. The parameter
    /// is neither clamped nor interpreted by this generic algorithm.
    public func value<Parameter, Failure: Swift.Error>(
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

    /// Subdivide using the same explicit interpolation contract as evaluation.
    ///
    /// With affine interpolation and t in [0, 1], the returned curves parameterize
    /// the original intervals [0, t] and [t, 1]. Each retains the declared degree.
    public func split<Parameter, Failure: Swift.Error>(
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
    /// A constant, degree-zero curve.
    public init(point: Point) { self.controlPoints = [point] }

    public init(start: Point, end: Point) {
        self.controlPoints = [start, end]
    }

    public init(start: Point, control: Point, end: Point) {
        self.controlPoints = [start, control, end]
    }

    public init(start: Point, control1: Point, control2: Point, end: Point) {
        self.controlPoints = [start, control1, control2, end]
    }

    // Only operations known to preserve nonemptiness may use this initializer.
    private init(nonempty controlPoints: [Point]) { self.controlPoints = controlPoints }
}
