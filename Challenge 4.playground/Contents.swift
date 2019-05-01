
import Foundation

struct Voucher {
    let date: Date
    let status: Status
    let identifier: String
}

extension Voucher {

    struct Date {
        let day: Component
        let month: Component
        let year: Component
    }
}

extension Voucher.Date {

    struct Component {
        private let value: Int
    }
}

extension Voucher {

    enum Status {
        case available
        case activated
        case redeemed
        case expired
    }
}

// MARK: - Initialization

extension Voucher.Date.Component {

    struct NonIntegerError<S: StringProtocol>: Error {
        let string: S
    }

    init<S: StringProtocol>(_ string: S) throws {

        guard let value = Int(string) else { throw NonIntegerError(string: string) }

        self.value = value
    }
}

extension Voucher.Date {

    init<S: StringProtocol>(_ string: S) throws {

        let index = { string.index(string.startIndex, offsetBy: $0) }

        year = try Component(string[index(0)..<index(2)])
        month = try Component(string[index(2)..<index(4)])
        day = try Component(string[index(4)..<index(6)])
    }
}

extension Voucher.Status {

    struct UnknownStatus: Error {}

    init<S: StringProtocol>(_ string: S) throws {
        switch string {
        case "Available": self = .available
        case "Activated": self = .activated
        case "Redeemed": self = .redeemed
        case "Expired": self = .expired
        default: throw UnknownStatus()
        }
    }
}

extension Voucher {

    init<S: StringProtocol>(_ string: S) throws {
        let components = string.split(separator: ":")
        date = try Date(components[0])
        status = try Status(components[1])
        identifier = String(components[2])
    }
}

// MARK - CustomStringConvertible

extension Voucher: CustomStringConvertible {
    var description: String { return [date.description, status.description, identifier].joined(separator: ":") }
}

extension Voucher.Date: CustomStringConvertible {
    var description: String { return "\(year)\(month)\(day)" }
}

extension Voucher.Date.Component: CustomStringConvertible {
    var description: String { return String(format: "%02d", value) }
}

extension Voucher.Status: CustomStringConvertible {

    var description: String {
        switch self {
        case .available: return "Available"
        case .activated: return "Activated"
        case .redeemed: return "Redeemed"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Comparable

extension Voucher.Date.Component: Comparable {

    static func < (lhs: Voucher.Date.Component, rhs: Voucher.Date.Component) -> Bool {
        return lhs.value < rhs.value
    }
}

extension Voucher.Date: Comparable {

    static func < (lhs: Voucher.Date, rhs: Voucher.Date) -> Bool {
        return (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

extension Voucher.Status: Comparable {

    static func < (lhs: Voucher.Status, rhs: Voucher.Status) -> Bool {

        func value(_ status: Voucher.Status) -> Int {
            switch status {
            case .activated: return 0
            case .available: return 1
            case .redeemed: return 2
            case .expired: return 3
            }
        }

        return value(lhs) < value(rhs)
    }
}

extension Voucher: Comparable {

    static func < (lhs: Voucher, rhs: Voucher) -> Bool {

        switch (lhs.status, rhs.status) {

        case (.activated, .activated),
             (.activated, .available),
             (.available, .activated),
             (.available, .available):
            return (lhs.date, lhs.status, lhs.identifier) < (rhs.date, rhs.status, rhs.identifier)

        case (.redeemed, .redeemed),
             (.redeemed, .expired),
             (.expired, .redeemed),
             (.expired, .expired):
            return (rhs.date, lhs.status, lhs.identifier) < (lhs.date, rhs.status, rhs.identifier)

        default:
            return lhs.status < rhs.status
        }
    }
}

// MARK: - Sort Vouchers

func sortVouchers(_ input: String) throws -> String {

    return try input
        .split(separator: ",")
        .map(Voucher.init)
        .sorted()
        .map { $0.description }
        .joined(separator: ",")
}

// MARK: - "Tests"

let longInput = "190112:Available:aaaa,190112:Activated:bbbb,190111:Available:cccc,190110:Redeemed:dddd,190110:Expired:eeee,190111:Activated:ffff,190111:Expired:gggg,190111:Redeemed:hhhh"

let input = "190112:Available:aaaa,190112:Activated:bbbb,190111:Available:cccc,190110:Redeemed:dddd,190110:Expired:eeee,190111:Activated:ffff"
let expected = "190111:Activated:ffff,190111:Available:cccc,190112:Activated:bbbb,190112:Available:aaaa,190110:Redeemed:dddd,190110:Expired:eeee"

let vouchers = try sortVouchers(input)

print("Valid?", vouchers == expected)
