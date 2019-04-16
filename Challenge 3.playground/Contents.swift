
// MARK: - Core types

struct Board {
    let spaces: [[Space]]
    var player: Position
    var boxes: [Position]
}

enum Space {
    case empty
    case wall
    case storage
}

struct Position: Equatable {
    let x: Int
    let y: Int
}

enum Direction {
    case up
    case down
    case left
    case right
}

struct MovementError: Swift.Error {
    
    enum Reason {
        case playerOnWall
        case boxOnWall
        case boxOnBox
    }
    
    let reason: Reason
    let position: Position
}

// MARK: - Initialization

extension Direction {

    init(_ character: Character) throws {
        struct UnknownDirectionError: Error {}
        switch character {
        case "U", "u": self = .up
        case "D", "d": self = .down
        case "L", "l": self = .left
        case "R", "r": self = .right
        default: throw UnknownDirectionError()
        }
    }
}

extension Array where Element == Direction {

    init(string: String) throws {
        self = try string.map(Direction.init)
    }
}

extension Space {

    init(_ character: Character) {
        switch character {
        case "#": self = .wall
        case "*", "P", "B": self = .storage
        default: self = .empty
        }
    }
}

extension Board {

    init(array: [String]) throws {

        spaces = array.map { $0.map(Space.init) }

        func positions(of characters: [Character]) -> [Position] {

            return array.enumerated().flatMap { y in
                return y.element.enumerated().compactMap { x in

                    guard characters.contains(x.element) else { return nil }

                    return Position(x: x.offset, y: y.offset)
                }
            }
        }

        struct NoPlayerError: Error {}
        guard let player = positions(of: ["p", "P"]).first else { throw NoPlayerError() }

        self.player = player
        boxes = positions(of: ["b", "B"])
    }
}

// MARK: - Output

extension Board {

    var array: [String] {

        return spaces.enumerated().map { y in
            y.element.enumerated().map { x in

                let position = Position(x: x.offset, y: y.offset)
                let space = x.element
                let isPlayer = position == player
                let isBox = boxes.contains(position)

                switch (space, isPlayer, isBox) {
                case (.empty, true, false): return "p"
                case (.storage, true, false): return "P"
                case (.empty, false, true): return "b"
                case (.storage, false, true): return "B"
                default: return space.description
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

extension Space: CustomStringConvertible {

    var description: String {
        switch self {
        case .wall: return "#"
        case .storage: return "*"
        default: return " "
        }
    }
}

extension Position: CustomStringConvertible {

    var description: String {
        return "(x: \(x), y: \(y))"
    }
}

// MARK: - Logic

extension Board {

    private func positions(of space: Space) -> [Position] {
        return spaces.enumerated().flatMap { y in
            return y.element.enumerated().compactMap { x in
                guard x.element == space else { return nil }
                return Position(x: x.offset, y: y.offset)
            }
        }
    }

    mutating func move(in direction: Direction) throws {

        let newPlayer = player.moving(in: direction)

        guard !positions(of: .wall).contains(newPlayer) else {
            throw MovementError(reason: .playerOnWall, position: newPlayer)
        }

        let newBoxes = try boxes.map { box -> Position in

            guard box == newPlayer else { return box }

            let newBox = box.moving(in: direction)

            guard !positions(of: .wall).contains(newBox) else {
                throw MovementError(reason: .boxOnWall, position: newBox)
            }

            guard !boxes.contains(newBox) else {
                throw MovementError(reason: .boxOnBox, position: newBox)
            }

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

// MARK: - Challenge Functions

func processSokobanMove(board stringBoard: [String], move stringMove: String) -> [String] {

    guard let move = stringMove.first else { return [] }

    do {
        var board = try Board(array: stringBoard)
        let direction = try Direction(move)
        try board.move(in: direction)
        return board.array

    } catch {
        print(error)
        return []
    }
}

// MARK: - Running the thing

let start = ["#############",
             "#p        * #",
             "#     b  b  #",
             "# *         #",
             "#############"]

//let new = processSokobanMove(board: start, move: "R")
//print(new)

do {

    var board = try Board(array: start)
    print(board)

    let directions = try Array(string: "RRRRRDRDLLLLRRRRRRULUR")
    for direction in directions {
        try board.move(in: direction)
        print(board)
    }

} catch {
    print(error)
}
