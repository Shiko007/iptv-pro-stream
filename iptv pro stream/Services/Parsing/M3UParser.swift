import Foundation

nonisolated struct M3UParser: Sendable {
    struct ParseResult: Sendable {
        var channels: [Channel]
        var epgURL: String?
    }

    func parse(_ content: String, providerID: UUID) -> ParseResult {
        var channels: [Channel] = []
        var epgURL: String?

        let lines = content.components(separatedBy: .newlines)
        var currentAttributes: [String: String] = [:]
        var currentName = ""
        var order = 0
        var currentGroupFromExtGrp: String?

        for line in lines {
            let trimmedLine = line.trimmed

            if trimmedLine.isEmpty { continue }

            // Parse #EXTM3U header for EPG URL
            if trimmedLine.hasPrefix("#EXTM3U") {
                epgURL = extractAttribute(from: trimmedLine, key: "url-tvg")
                    ?? extractAttribute(from: trimmedLine, key: "x-tvg-url")
                continue
            }

            // Parse #EXTINF line
            if trimmedLine.hasPrefix("#EXTINF:") {
                let info = String(trimmedLine.dropFirst("#EXTINF:".count))
                currentAttributes = parseEXTINF(info)
                // Extract channel name (after the last comma)
                if let commaRange = info.range(of: ",", options: .backwards) {
                    currentName = String(info[commaRange.upperBound...]).trimmed
                }
                continue
            }

            // Parse #EXTGRP
            if trimmedLine.hasPrefix("#EXTGRP:") {
                currentGroupFromExtGrp = String(trimmedLine.dropFirst("#EXTGRP:".count)).trimmed
                continue
            }

            // Skip other directives
            if trimmedLine.hasPrefix("#") { continue }

            // This is a URL line
            if trimmedLine.isValidURL || trimmedLine.hasPrefix("rtmp://") || trimmedLine.hasPrefix("rtsp://") || trimmedLine.hasPrefix("mms://") {
                let groupTitle = currentGroupFromExtGrp ?? currentAttributes["group-title"] ?? "Uncategorized"

                var channel = Channel(
                    name: currentName.isEmpty ? "Channel \(order + 1)" : currentName,
                    logoURL: currentAttributes["tvg-logo"],
                    groupTitle: groupTitle,
                    streamURL: trimmedLine,
                    streamType: .live,
                    epgChannelID: currentAttributes["tvg-id"] ?? currentAttributes["tvg-name"],
                    providerID: providerID,
                    order: order
                )

                if let catchupSource = currentAttributes["catchup-source"] {
                    channel.catchupSource = catchupSource
                }
                if let catchupDays = currentAttributes["catchup-days"], let days = Int(catchupDays) {
                    channel.catchupDays = days
                }

                channels.append(channel)
                order += 1

                // Reset for next channel
                currentAttributes = [:]
                currentName = ""
                currentGroupFromExtGrp = nil
            }
        }

        return ParseResult(channels: channels, epgURL: epgURL)
    }

    private func parseEXTINF(_ info: String) -> [String: String] {
        var attributes: [String: String] = [:]

        // Match key="value" patterns
        let pattern = #"([\w-]+)="([^"]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return attributes }

        let range = NSRange(info.startIndex..., in: info)
        let matches = regex.matches(in: info, range: range)

        for match in matches {
            if let keyRange = Range(match.range(at: 1), in: info),
               let valueRange = Range(match.range(at: 2), in: info) {
                let key = String(info[keyRange])
                let value = String(info[valueRange])
                attributes[key] = value
            }
        }

        return attributes
    }

    private func extractAttribute(from line: String, key: String) -> String? {
        let pattern = "\(key)=\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let range = Range(match.range(at: 1), in: line) else {
            return nil
        }
        return String(line[range])
    }
}
