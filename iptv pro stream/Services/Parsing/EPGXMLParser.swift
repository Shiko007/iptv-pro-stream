import Foundation

final class EPGXMLParser: NSObject, XMLParserDelegate, Sendable {

    nonisolated func parse(data: Data) -> [EPGProgramme] {
        let parser = XMLParser(data: data)
        let delegate = EPGXMLParserDelegate()
        parser.delegate = delegate
        parser.parse()
        return delegate.programmes
    }

    nonisolated func parse(url: URL) async throws -> [EPGProgramme] {
        let data = try await NetworkClient.shared.fetchData(from: url)
        return parse(data: data)
    }
}

private final class EPGXMLParserDelegate: NSObject, XMLParserDelegate {
    var programmes: [EPGProgramme] = []

    private var currentElement = ""
    private var currentChannelID = ""
    private var currentTitle = ""
    private var currentDesc = ""
    private var currentStart = ""
    private var currentStop = ""
    private var currentLang = ""
    private var currentCategory = ""
    private var isInProgramme = false
    private var isInTitle = false
    private var isInDesc = false
    private var isInCategory = false
    private var characterBuffer = ""

    private static let xmltvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let xmltvDateFormatterNoTZ: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        characterBuffer = ""

        switch elementName {
        case "programme":
            isInProgramme = true
            currentChannelID = attributeDict["channel"] ?? ""
            currentStart = attributeDict["start"] ?? ""
            currentStop = attributeDict["stop"] ?? ""
            currentTitle = ""
            currentDesc = ""
            currentLang = ""
            currentCategory = ""
        case "title":
            isInTitle = true
            currentLang = attributeDict["lang"] ?? ""
        case "desc":
            isInDesc = true
        case "category":
            isInCategory = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        characterBuffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "title":
            if isInTitle { currentTitle = characterBuffer.trimmed }
            isInTitle = false
        case "desc":
            if isInDesc { currentDesc = characterBuffer.trimmed }
            isInDesc = false
        case "category":
            if isInCategory { currentCategory = characterBuffer.trimmed }
            isInCategory = false
        case "programme":
            if isInProgramme {
                if let start = parseXMLTVDate(currentStart),
                   let stop = parseXMLTVDate(currentStop),
                   !currentTitle.isEmpty {
                    let programme = EPGProgramme(
                        channelID: currentChannelID,
                        title: currentTitle,
                        description: currentDesc.isEmpty ? nil : currentDesc,
                        startTime: start,
                        endTime: stop,
                        lang: currentLang.isEmpty ? nil : currentLang,
                        categoryName: currentCategory.isEmpty ? nil : currentCategory
                    )
                    programmes.append(programme)
                }
            }
            isInProgramme = false
        default:
            break
        }
        characterBuffer = ""
    }

    private func parseXMLTVDate(_ string: String) -> Date? {
        Self.xmltvDateFormatter.date(from: string) ??
        Self.xmltvDateFormatterNoTZ.date(from: string)
    }
}
