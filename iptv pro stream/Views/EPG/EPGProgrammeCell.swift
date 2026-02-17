import SwiftUI

struct EPGProgrammeCell: View {
    let programme: EPGProgramme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(programme.title)
                .font(.caption.bold())
                .lineLimit(2)

            Text(timeRange)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if programme.isCurrentlyAiring {
                ProgressView(value: programme.progress)
                    .tint(.accentColor)
            }
        }
        .padding(8)
        .frame(width: cellWidth, alignment: .leading)
        .background(programme.isCurrentlyAiring ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: programme.startTime)) - \(formatter.string(from: programme.endTime))"
    }

    private var cellWidth: CGFloat {
        let duration = programme.endTime.timeIntervalSince(programme.startTime)
        let minutes = duration / 60
        return max(100, CGFloat(minutes) * 2.5)
    }
}
