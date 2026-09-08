import Bezier
import Point
import Tagged
import Testing

@Suite
struct `Bezier point call sites` {
    @Test
    func `Curves retain three dimensional point types`() {
        let curve = Bezier(
            start: Point(x: 0, y: 1, z: 2),
            control: Point(x: 3, y: 4, z: 5),
            end: Point(x: 6, y: 7, z: 8)
        )
        #expect(curve.start.coordinates == Vector(x: 0, y: 1, z: 2))
        #expect(curve.reversed.start == Point(x: 6, y: 7, z: 8))
    }

    private enum World {}

    @Test
    func `Evaluation retains the tagged domain`() {
        typealias Position = Tagged<World, Point<1, Int>>
        let start = Position(_unchecked: Point(x: 1))
        let end = Position(_unchecked: Point(x: 2))
        let curve = Bezier(start: start, end: end)
        let value: Position = curve.value(at: false) { a, b, chooseEnd in chooseEnd ? b : a }
        #expect(value == start)
        let reversed: Bezier<Position> = curve.reversed
        #expect(reversed.start == end)
    }
}
