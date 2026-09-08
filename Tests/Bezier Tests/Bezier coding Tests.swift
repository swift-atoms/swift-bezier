import Bezier
import Foundation
import Testing

@Suite
struct `Bezier coding` {
    @Test
    func `Control arrays round trip without losing declared degree`() throws {
        let curve = Bezier(start: 1, control: 1, end: 1)
        let data = try JSONEncoder().encode(curve)
        #expect(try JSONDecoder().decode([Int].self, from: data) == [1, 1, 1])
        #expect(try JSONDecoder().decode(Bezier<Int>.self, from: data) == curve)
        #expect(try JSONDecoder().decode(Bezier<Int>.self, from: Data("[5]".utf8)) == Bezier(point: 5))
    }

    @Test(arguments: ["[]", "null", "{}", "[1, null]"])
    func `Decoding cannot bypass the control list contract`(_ json: String) {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Bezier<Int>.self, from: Data(json.utf8))
        }
    }

    @Test
    func `One way scalar coding conformances remain independent`() throws {
        struct Output: Encodable { let value: Int }
        struct Input: Decodable { let value: Int }
        let data = try JSONEncoder().encode(Bezier(point: Output(value: 3)))
        let curve = try JSONDecoder().decode(Bezier<Input>.self, from: data)
        #expect(curve.start.value == 3)
        #expect(curve.degree == 0)
    }
}
