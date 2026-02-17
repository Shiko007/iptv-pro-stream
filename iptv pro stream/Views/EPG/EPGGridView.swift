import SwiftUI

struct EPGGridView: View {
    @State private var viewModel = EPGViewModel()
    @State private var selectedChannelID: String?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading EPG data...")
                } else if viewModel.programmes.isEmpty {
                    ContentUnavailableView(
                        "No EPG Data",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("EPG data is not available for the current channels.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.channelIDs, id: \.self) { channelID in
                                EPGChannelRow(
                                    channelID: channelID,
                                    channelName: viewModel.channelName(for: channelID),
                                    programmes: viewModel.programmes(for: channelID)
                                )
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("TV Guide")
            .task {
                await viewModel.load()
            }
        }
    }
}
