import Foundation

nonisolated struct EPGProgramme: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var channelID: String
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var lang: String?
    var categoryName: String?

    var isCurrentlyAiring: Bool {
        let now = Date()
        return now >= startTime && now < endTime
    }

    var progress: Double {
        let now = Date()
        guard now >= startTime else { return 0 }
        guard now < endTime else { return 1 }
        let total = endTime.timeIntervalSince(startTime)
        let elapsed = now.timeIntervalSince(startTime)
        return elapsed / total
    }

    var hasEnded: Bool {
        Date() >= endTime
    }

    init(id: String = UUID().uuidString, channelID: String, title: String, description: String? = nil, startTime: Date, endTime: Date, lang: String? = nil, categoryName: String? = nil) {
        self.id = id
        self.channelID = channelID
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.lang = lang
        self.categoryName = categoryName
    }
}
