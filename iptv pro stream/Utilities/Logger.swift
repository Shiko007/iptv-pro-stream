import Foundation
import os

enum AppLogger {
    private static let subsystem = Constants.App.bundleID

    static let general = Logger(subsystem: subsystem, category: "General")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let parser = Logger(subsystem: subsystem, category: "Parser")
    static let player = Logger(subsystem: subsystem, category: "Player")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
