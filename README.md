# Bezier

One polynomial Bézier curve with a nonempty, immutable control-point list.
The point type carries its dimensionality and any domain/frame tag.

```swift
import Bezier
import Point

let curve = Bezier(
    start: Point(x: 0.0, y: 0.0),
    control: Point(x: 1.0, y: 2.0),
    end: Point(x: 2.0, y: 0.0)
)
let cubic = Bezier(start: 0.0, control1: 1.0, control2: 3.0, end: 4.0)
let midpoint = cubic.value(at: 0.5) { a, b, t in a + (b - a) * t }
let halves = cubic.split(at: 0.5) { a, b, t in a + (b - a) * t }
```

The general `init(controlPoints:)` throws `Bezier<Point>.Error.empty` for an
empty list. Known-count constructors cannot fail. `init(point:)` represents a
degree-zero constant curve; repeated points and lower effective degree are valid.
The declared `degree` is always the number of controls minus one, not a claim
about the minimal polynomial degree. Endpoints are not optional.

Equality and hashing compare the control polygon in order, not geometric loci.
Reversal reverses that order. `map` maps controls and preserves count; only an
affine point mapping generally commutes with evaluation.

De Casteljau evaluation and subdivision accept explicit interpolation and propagate
its typed errors. They require no numeric, coordinate, frame, platform or Affine
dependency. The supplied interpolation must obey the desired affine laws; the
algorithm cannot prove those laws or repair scalar overflow/nonfinite arithmetic.
Parameters are not clamped, so extrapolation is possible. A constant curve never
calls interpolation. Metric-dependent operations such as length and normalization
are not part of this representation.

Conditional coding uses an ordered array and rejects an empty array on decoding.
Encoding and decoding conformances are independent. Production uses Swift only;
Point and Tagged are explicit test dependencies. Resolve their URLs locally with
`atoms.xcworkspace`.
