
struct Board {
    let spaces: [[Space]]
    var player: Position
    var boxes: [Position]
}

extension Board {

    struct Space {
        let kind: Kind
    }
}

extension Board.Space {

    enum Kind {
        case empty
        case wall
        case storage
    }
}

enum Direction {
    case up
    case down
    case left
    case right
}

extension Direction {

    init(_ character: Character) throws {
        struct UnknownDirectionError: Error {}
        switch character {
        case "U": self = .up
        case "D": self = .down
        case "L": self = .left
        case "R": self = .right
        default: throw UnknownDirectionError()
        }
    }
}

extension Board.Space.Kind {

    init(_ character: Character) {
        switch character {
        case "#": self = .wall
        case "*", "P", "B": self = .storage
        default: self = .empty
        }
    }
}

struct Position: Equatable {
    let x: Int
    let y: Int
}

extension Board {

    init(array: [String]) throws {

        spaces = array.map { line in
            line.map { character in
                let kind = Board.Space.Kind(character)
                return Board.Space(kind: kind)
            }
        }

        func positions(of characters: [Character]) -> [Position] {

            return array.enumerated().flatMap { y in
                return y.element.enumerated().compactMap { x in

                    guard characters.contains(x.element) else { return nil }

                    return Position(x: x.offset, y: y.offset)
                }
            }
        }

        player = positions(of: ["p", "P"]).first!
        boxes = positions(of: ["b", "B"])
    }

    var array: [String] {

        return spaces.enumerated().map { y in
            y.element.enumerated().map { x in

                let position = Position(x: x.offset, y: y.offset)
                let kind = x.element.kind
                let isPlayer = position == player
                let isBox = boxes.contains(position)

                switch (kind, isPlayer, isBox) {
                case (.empty, true, false): return "p"
                case (.storage, true, false): return "P"
                case (.empty, false, true): return "b"
                case (.storage, false, true): return "B"
                default: return kind.description
                }

            }.joined()
        }
    }
}

extension Board: CustomStringConvertible {

    var description: String {
        return array.joined(separator: "\n")
    }
}

extension Board.Space.Kind: CustomStringConvertible {

    var description: String {
        switch self {
        case .wall: return "#"
        case .storage: return "*"
        default: return " "
        }
    }
}

extension Board {

    func positions(of kind: Board.Space.Kind) -> [Position] {
        return spaces.enumerated().flatMap { y in
            return y.element.enumerated().compactMap { x in
                guard x.element.kind == kind else { return nil }
                return Position(x: x.offset, y: y.offset)
            }
        }
    }

    mutating func move(_ directions: [Direction]) throws {
        for direction in directions {
            try move(direction)
        }
    }

    mutating func move(_ direction: Direction) throws {

        let newPlayer = player.moving(in: direction)

        struct PlayerOnWallError: Error {
            let position: Position
        }
        guard !positions(of: .wall).contains(newPlayer) else { throw PlayerOnWallError(position: newPlayer) }

        let newBoxes = try boxes.map { box -> Position in

            guard box == newPlayer else { return box }

            let newBox = box.moving(in: direction)

            struct BoxOnWallError: Error {
                let position: Position
            }
            guard !positions(of: .wall).contains(newBox) else { throw BoxOnWallError(position: newBox) }

            struct BoxOnBoxError: Error {
                let position: Position
            }
            guard !boxes.contains(newBox) else { throw BoxOnBoxError(position: newBox) }

            return newBox
        }

        boxes = newBoxes
        player = newPlayer
    }
}

extension Position {
    func moving(in direction: Direction) -> Position {
        switch direction {
        case .up: return Position(x: x, y: y - 1)
        case .down: return Position(x: x, y: y + 1)
        case .left: return Position(x: x - 1, y: y)
        case .right: return Position(x: x + 1, y: y)
        }
    }
}

extension Array where Element == Direction {

    init(string: String) throws {
        self = try string.map(Direction.init)
    }
}

do {

    var board = try Board(array: ["#############",
                                  "#p        * #",
                                  "#     b  b  #",
                                  "# *         #",
                                  "#############"])

    print(board)

    let directions = try Array(string: "RRRRRDRDLLLLRRRRRRULUR")
    for direction in directions {
        try board.move(direction)
        print(board)
    }

} catch {
    print(error)
}
