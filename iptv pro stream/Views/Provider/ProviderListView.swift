import SwiftUI

struct ProviderListView: View {
    var onProviderAdded: (() -> Void)?
    @State private var viewModel = ProviderListViewModel()
    @State private var showingAddProvider = false
    @State private var providerToDelete: Provider?

    var body: some View {
        Group {
            if viewModel.providers.isEmpty && !viewModel.isLoading {
                ContentUnavailableView {
                    Label("No Providers", systemImage: "antenna.radiowaves.left.and.right.slash")
                } description: {
                    Text("Add an M3U or Xtream Codes provider to start streaming.")
                } actions: {
                    Button {
                        showingAddProvider = true
                    } label: {
                        Label("Add Provider", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(viewModel.providers) { provider in
                        ProviderRowView(
                            provider: provider,
                            isSyncing: viewModel.syncingProviderID == provider.id
                        ) {
                            Task { await viewModel.syncProvider(provider) }
                        }
                        #if !os(tvOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                providerToDelete = provider
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                Task { await viewModel.syncProvider(provider) }
                            } label: {
                                Label("Sync", systemImage: "arrow.clockwise")
                            }
                            Button(role: .destructive) {
                                providerToDelete = provider
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        #endif
                    }
                }
            }
        }
        .navigationTitle("Providers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddProvider = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProvider) {
            ProviderFormView { provider in
                Task {
                    await viewModel.addProvider(provider)
                    onProviderAdded?()
                }
            }
        }
        .alert("Delete Provider", isPresented: Binding(
            get: { providerToDelete != nil },
            set: { if !$0 { providerToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                providerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let provider = providerToDelete {
                    Task { await viewModel.deleteProvider(provider) }
                    providerToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(providerToDelete?.name ?? "")\"? All cached channels and data for this provider will be removed.")
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.syncAllProviders()
        }
    }
}

struct ProviderRowView: View {
    let provider: Provider
    let isSyncing: Bool
    let onSync: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(provider.name)
                        .font(.headline)
                    Spacer()
                    Text(provider.type == .m3u ? "M3U" : "Xtream")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(provider.type == .m3u ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .clipShape(Capsule())
                }
                HStack {
                    Text("\(provider.channelCount) channels")
                    if provider.vodCount > 0 {
                        Text("· \(provider.vodCount) movies")
                    }
                    if provider.seriesCount > 0 {
                        Text("· \(provider.seriesCount) series")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let lastSynced = provider.lastSynced {
                    Text("Synced \(lastSynced.timeAgoDisplay())")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if isSyncing {
                ProgressView()
            } else {
                Button {
                    onSync()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}
