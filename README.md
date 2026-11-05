# swift-bezier

Use this package when you need a Bézier curve of any degree over a point type you choose, and you want to evaluate it, subdivide it, reverse it or map its control points without the curve knowing anything about your coordinate arithmetic. Start from `Bezier<Point>`. The caller supplies the interpolation, so the same curve works for plain scalars, `Point` from swift-point, or domain-tagged points, and keeps their types. For a straight piece between two points with no control polygon, use Segment<Point> from swift-segment. For a closed chain of vertices, use Polygon<Point> from swift-polygon.

## Laws

- A curve is its control polygon, and `degree` is always `controlPoints.count - 1`. The degree is never reduced: three equal control points still make a degree-2 curve. Equality and hashing compare the control points in order. A curve and its `reversed` are therefore unequal unless the control points read the same in both orders, and so are two control polygons that trace the same geometry.
- `value(at:interpolating:)` and `split(at:interpolating:)` run de Casteljau's algorithm with the closure you pass. The geometric laws below hold only when that closure is a linear interpolation, that is `interpolate(a, b, 0) == a`, `interpolate(a, b, 1) == b`, and affine in between:
  - `value(at: 0)` is `start` and `value(at: 1)` is `end`.
  - The parameter is not clamped. Values outside `0...1` extrapolate.
  - `split(at: t)` returns two curves of the original degree. `left.start == start`, `right.end == end` and `left.end == right.start`. `left` evaluated at `u` equals the original at `u * t`, and `right` evaluated at `u` equals the original at `t + u * (1 - t)`.
  - Splitting at `0` gives a constant `left` and `right == self`. Splitting at `1` gives `left == self` and a constant `right`.
  - `reversed` evaluated at `u` equals the original at `1 - u`, and `reversed.reversed == self`.
- A degree-0 curve never calls the interpolation closure. Its value is its single point, and both halves of a split are the curve itself.
- `map` transforms the control points in order. It stops at the first transform that throws, and the error propagates unchanged. Evaluation and subdivision also stop at the first interpolation that throws.
- A curve encodes as a bare array of its control points. Decoding rejects an empty array, so a decoded curve keeps the non-empty invariant that `init(controlPoints:)` enforces.
