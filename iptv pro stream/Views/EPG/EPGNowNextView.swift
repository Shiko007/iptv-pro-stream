import SwiftUI

struct EPGNowNextView: View {
    let now: EPGProgramme?
    let next: EPGProgramme?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let now {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Now: \(now.title)")
                        .font(.caption.bold())
                        .lineLimit(1)
                }
                ProgressView(value: now.progress)
                    .tint(.red)
            }

            if let next {
                Text("Next: \(next.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
