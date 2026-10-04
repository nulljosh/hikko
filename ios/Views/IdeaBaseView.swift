import SwiftUI

struct IdeaBaseView: View {
    @Environment(AppState.self) private var appState
    @State private var topic = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var message: String?
    @State private var ideaBases: [IdeaBase] = []
    @State private var rfs: [RFSEntry] = []
    @State private var isLoadingMore = false
    @State private var reachedEnd = false

    var body: some View {
        NavigationStack {
            Form {
                if !rfs.isEmpty {
                    Section("Inspiration \u{2014} YC Requests for Startups") {
                        ForEach(rfs) { entry in
                            Link(destination: URL(string: entry.url)!) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("By \(entry.author)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(entry.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }

                if appState.isLoggedIn {
                    Section("Generate Ideas on a Topic") {
                        TextField("Topic", text: $topic)
                        TextField("Context (optional)", text: $description, axis: .vertical)
                            .lineLimit(2...4)
                        Button(action: submit) {
                            if isSubmitting {
                                ProgressView().frame(maxWidth: .infinity)
                            } else {
                                Text("Queue Generation")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(topic.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                        if let msg = message {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Recent Idea Bases") {
                    if ideaBases.isEmpty {
                        Text("No idea bases yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(ideaBases) { ib in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ib.topic)
                                    .font(.subheadline.weight(.medium))
                                HStack {
                                    Text(ib.pending == true ? "Pending" : "Done")
                                        .font(.caption2)
                                        .foregroundStyle(ib.pending == true ? .orange : .green)
                                    Spacer()
                                    Text("\(ib.postIds?.count ?? 0) ideas")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onAppear {
                                if ib.id == ideaBases.last?.id { loadMore() }
                            }
                        }
                        if isLoadingMore {
                            ProgressView().frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.paper)
            .navigationTitle("Idea Base")
            .task {
                ideaBases = (try? await appState.api.fetchIdeaBases(offset: 0)) ?? []
                rfs = (try? await appState.api.fetchRfs()) ?? []
            }
        }
    }

    private func loadMore() {
        guard !isLoadingMore, !reachedEnd else { return }
        isLoadingMore = true
        Task {
            let more = (try? await appState.api.fetchIdeaBases(offset: ideaBases.count)) ?? []
            if more.isEmpty { reachedEnd = true } else { ideaBases.append(contentsOf: more) }
            isLoadingMore = false
        }
    }

    private func submit() {
        isSubmitting = true
        message = nil
        Task {
            do {
                _ = try await appState.api.createIdeaBase(
                    topic: topic,
                    description: description.isEmpty ? nil : description
                )
                message = "Queued. Ideas will appear in feed within 5 minutes."
                topic = ""
                description = ""
                ideaBases = (try? await appState.api.fetchIdeaBases(offset: 0)) ?? []
            } catch {
                message = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
