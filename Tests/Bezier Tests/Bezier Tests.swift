import Bezier
import Testing

@Suite
struct `Bezier contracts` {
    private func interpolate(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    @Test
    func `Empty control lists are rejected with the owned error`() {
        do {
            _ = try Bezier<Int>(controlPoints: [])
            Issue.record("Expected an empty control list to fail")
        } catch {
            let failure: Bezier<Int>.Error = error
            #expect(failure == .empty)
        }
    }

    @Test
    func `Constant curves are valid and do not call interpolation`() {
        let curve = Bezier(point: "constant")
        #expect(curve.degree == 0)
        #expect(curve.start == curve.end)
        var calls = 0
        let value = curve.value(at: 0.5) { a, _, _ in calls += 1; return a }
        let parts = curve.split(at: 0.5) { a, _, _ in calls += 1; return a }
        #expect(value == "constant")
        #expect(calls == 0)
        #expect(parts.left == curve)
        #expect(parts.right == curve)
    }

    @Test
    func `Natural constructors preserve control order and declared degree`() {
        #expect(Bezier(start: 1, end: 2).controlPoints == [1, 2])
        #expect(Bezier(start: 1, control: 2, end: 3).degree == 2)
        let cubic = Bezier(start: 1, control1: 2, control2: 3, end: 4)
        #expect(cubic.controlPoints == [1, 2, 3, 4])
        #expect(cubic.degree == 3)
        #expect(Bezier(start: 1, control: 1, end: 1).degree == 2)
    }

    @Test
    func `General construction retains higher degrees and value semantics`() throws {
        var controls = [0, 1, 2, 3, 4, 5]
        let curve = try Bezier(controlPoints: controls)
        controls.removeAll()
        #expect(curve.degree == 5)
        #expect(curve.start == 0)
        #expect(curve.end == 5)
        #expect(curve.reversed.controlPoints == [5, 4, 3, 2, 1, 0])
        #expect(curve.reversed.reversed == curve)
    }

    @Test
    func `Evaluation preserves endpoints and permits extrapolation`() {
        let curve = Bezier(start: 0.0, control: 2.0, end: 4.0)
        #expect(curve.value(at: 0.0, interpolating: interpolate) == 0)
        #expect(curve.value(at: 0.5, interpolating: interpolate) == 2)
        #expect(curve.value(at: 1.0, interpolating: interpolate) == 4)
        #expect(curve.value(at: 2.0, interpolating: interpolate) == 8)
        #expect(Bezier(start: 0.0, control: 4.0, end: 0.0)
            .value(at: 0.5, interpolating: interpolate) == 2)
    }

    @Test
    func `Subdivision preserves degree and parameterized values`() {
        let curve = Bezier(start: 0.0, control1: 2.0, control2: -1.0, end: 4.0)
        let parts = curve.split(at: 0.5, interpolating: interpolate)
        #expect(parts.left.start == curve.start)
        #expect(parts.right.end == curve.end)
        #expect(parts.left.end == parts.right.start)
        #expect(parts.left.degree == curve.degree)
        #expect(parts.right.degree == curve.degree)
        for u in [0.0, 0.25, 0.5, 0.75, 1.0] {
            #expect(parts.left.value(at: u, interpolating: interpolate)
                == curve.value(at: u * 0.5, interpolating: interpolate))
            #expect(parts.right.value(at: u, interpolating: interpolate)
                == curve.value(at: 0.5 + u * 0.5, interpolating: interpolate))
            #expect(curve.reversed.value(at: u, interpolating: interpolate)
                == curve.value(at: 1 - u, interpolating: interpolate))
        }
    }

    @Test
    func `Endpoint subdivision retains constant and original control polygons`() {
        let curve = Bezier(start: 0.0, control: 2.0, end: 4.0)
        let atStart = curve.split(at: 0.0, interpolating: interpolate)
        #expect(atStart.left.controlPoints == [0, 0, 0])
        #expect(atStart.right == curve)
        let atEnd = curve.split(at: 1.0, interpolating: interpolate)
        #expect(atEnd.left == curve)
        #expect(atEnd.right.controlPoints == [4, 4, 4])
    }

    @Test
    func `Control mapping preserves order and stops on typed failure`() {
        enum Failure: Error { case rejected }
        let curve = Bezier(start: 1, control: 2, end: 3)
        #expect(curve.map(String.init).controlPoints == ["1", "2", "3"])
        var visited: [Int] = []
        do {
            _ = try curve.map { (point: Int) throws(Failure) -> Int in
                visited.append(point)
                if point == 2 { throw .rejected }
                return point
            }
            Issue.record("Expected mapping to fail")
        } catch {
            let failure: Failure = error
            #expect(failure == .rejected)
        }
        #expect(visited == [1, 2])
    }

    @Test
    func `Evaluation and subdivision propagate the interpolation error`() {
        enum Failure: Error { case rejected }
        let curve = Bezier(start: 1, control: 2, end: 3)
        var calls = 0
        func fail(_ a: Int, _ b: Int, _ t: Int) throws(Failure) -> Int {
            calls += 1
            throw .rejected
        }
        do {
            _ = try curve.value(at: 0, interpolating: fail)
            Issue.record("Expected evaluation to fail")
        } catch {
            let failure: Failure = error
            #expect(failure == .rejected)
        }
        do {
            _ = try curve.split(at: 0, interpolating: fail)
            Issue.record("Expected subdivision to fail")
        } catch {
            let failure: Failure = error
            #expect(failure == .rejected)
        }
        #expect(calls == 2)
    }

    @Test
    func `Value conformances compare the control representation`() {
        let curve = Bezier(start: 1, end: 2)
        #expect(Set([curve, curve, curve.reversed]).count == 2)
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(curve)
    }
}
