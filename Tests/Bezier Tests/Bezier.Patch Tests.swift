import Bezier
import Foundation
import Testing

enum `Bezier.Patch Tests` {}

extension `Bezier.Patch Tests` {
    @Suite
    struct `Bezier patch contracts` {
        private func interpolate(_ a: Double, _ b: Double, _ t: Double) -> Double {
            a + (b - a) * t
        }

        private func patch() throws -> Bezier<Double>.Patch {
            try Bezier<Double>.Patch(controlPoints: [
                [0, 1, 4, 2],
                [3, -2, 5, 1],
                [7, 0, -1, 6],
            ])
        }

        @Test
        func `Empty and ragged control nets are rejected with the owned error`() {
            #expect(throws: Bezier<Int>.Error.empty) { try Bezier<Int>.Patch(rows: []) }
            #expect(throws: Bezier<Int>.Error.empty) { try Bezier<Int>.Patch(controlPoints: [[1], []]) }
            #expect(throws: Bezier<Int>.Error.ragged) { try Bezier<Int>.Patch(controlPoints: [[1, 2], [3]]) }
        }

        @Test
        func `Degrees follow the control net and are never reduced`() throws {
            let patch = try patch()
            #expect(patch.degree.u == 3)
            #expect(patch.degree.v == 2)
            #expect(patch.rows.count == 3)
            #expect(patch.columns.count == 4)
            #expect(patch.columns[1].controlPoints == [1, -2, 0])
            let constant = try Bezier<Int>.Patch(controlPoints: [[5]])
            #expect(constant.degree.u == 0)
            #expect(constant.degree.v == 0)
            let flat = try Bezier<Int>.Patch(controlPoints: [[1, 1], [1, 1]])
            #expect(flat.degree.u == 1)
            #expect(flat.degree.v == 1)
        }

        @Test
        func `The four corners are the corner control points`() throws {
            let patch = try patch()
            #expect(patch.value(at: 0, 0, interpolating: interpolate) == 0)
            #expect(patch.value(at: 1, 0, interpolating: interpolate) == 2)
            #expect(patch.value(at: 0, 1, interpolating: interpolate) == 7)
            #expect(patch.value(at: 1, 1, interpolating: interpolate) == 6)
        }

        @Test
        func `Boundary curves are the curves of the edge rows and columns`() throws {
            let patch = try patch()
            #expect(patch.row(at: 0, interpolating: interpolate) == patch.rows[0])
            #expect(patch.row(at: 1, interpolating: interpolate) == patch.rows[2])
            #expect(patch.column(at: 0, interpolating: interpolate) == patch.columns[0])
            #expect(patch.column(at: 1, interpolating: interpolate) == patch.columns[3])
        }

        @Test
        func `Rows and columns through a point agree with its value`() throws {
            let patch = try patch()
            for u in [-0.5, 0, 0.25, 0.5, 1, 1.5] {
                for v in [-0.25, 0, 0.125, 0.75, 1, 2] {
                    let value = patch.value(at: u, v, interpolating: interpolate)
                    let alongRow = patch.row(at: v, interpolating: interpolate)
                        .value(at: u, interpolating: interpolate)
                    let alongColumn = patch.column(at: u, interpolating: interpolate)
                        .value(at: v, interpolating: interpolate)
                    #expect(value == alongColumn)
                    #expect(abs(value - alongRow) < 1e-12)
                    #expect(patch.transposed.value(at: v, u, interpolating: interpolate) == alongRow)
                }
            }
        }

        @Test
        func `A bilinear patch is bilinear interpolation of its corners`() throws {
            let patch = try Bezier<Double>.Patch(controlPoints: [[0, 8], [16, 40]])
            #expect(patch.value(at: 0.5, 0.5, interpolating: interpolate) == 16)
            #expect(patch.value(at: 0.25, 0.5, interpolating: interpolate) == 12)
        }

        @Test
        func `Transposition swaps the parameters and is its own inverse`() throws {
            let patch = try patch()
            #expect(patch.transposed.degree.u == 2)
            #expect(patch.transposed.degree.v == 3)
            #expect(patch.transposed.rows == patch.columns)
            #expect(patch.transposed.transposed == patch)
        }

        @Test
        func `A constant patch never calls interpolation`() throws {
            let patch = try Bezier<String>.Patch(controlPoints: [["only"]])
            var calls = 0
            let value = patch.value(at: 0.5, 0.5) { a, _, _ in
                calls += 1
                return a
            }
            #expect(value == "only")
            #expect(calls == 0)
        }

        @Test
        func `Mapping preserves the net and stops on typed failure`() throws {
            struct Failure: Swift::Error, Equatable {}
            let patch = try Bezier<Int>.Patch(controlPoints: [[1, 2], [3, 4]])
            let doubled = patch.map { $0 * 2 }
            #expect(doubled.rows.map(\.controlPoints) == [[2, 4], [6, 8]])
            var visited: [Int] = []
            func transform(_ value: Int) throws(Failure) -> Int {
                visited.append(value)
                if value == 3 { throw Failure() }
                return value
            }
            #expect(throws: Failure()) { try patch.map(transform) }
            #expect(visited == [1, 2, 3])
        }

        @Test
        func `Evaluation propagates the interpolation error`() throws {
            struct Failure: Swift::Error, Equatable {}
            let patch = try Bezier<Int>.Patch(controlPoints: [[1, 2], [3, 4]])
            func fail(_ a: Int, _ b: Int, _ t: Int) throws(Failure) -> Int { throw Failure() }
            #expect(throws: Failure()) { try patch.value(at: 0, 0, interpolating: fail) }
            #expect(throws: Failure()) { try patch.row(at: 0, interpolating: fail) }
            #expect(throws: Failure()) { try patch.column(at: 0, interpolating: fail) }
        }

        @Test
        func `Value conformances compare the control net`() throws {
            func requireSendable<T: Sendable>(_ value: T) {}
            let patch = try Bezier<Int>.Patch(controlPoints: [[1, 2], [3, 4]])
            requireSendable(patch)
            #expect(Set([patch, patch, patch.transposed]).count == 2)
        }

        @Test
        func `A patch codes as a bare array of rows and decoding keeps its invariants`() throws {
            let patch = try Bezier<Int>.Patch(controlPoints: [[1, 2], [3, 4]])
            let data = try JSONEncoder().encode(patch)
            #expect(try JSONDecoder().decode([[Int]].self, from: data) == [[1, 2], [3, 4]])
            #expect(try JSONDecoder().decode(Bezier<Int>.Patch.self, from: data) == patch)
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(Bezier<Int>.Patch.self, from: Data("[]".utf8))
            }
            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(Bezier<Int>.Patch.self, from: Data("[[1,2],[3]]".utf8))
            }
        }
    }
}
