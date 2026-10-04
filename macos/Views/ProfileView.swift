import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var postToDelete: Post?
    @State private var confirmingDeleteAccount = false

    var myPosts: [Post] {
        guard let username = appState.user?.username else { return [] }
        return appState.posts.filter { $0.author?.username == username }
    }

    var body: some View {
        Group {
            if appState.isLoggedIn, let user = appState.user {
                List {
                    Section {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.sparkBlue.opacity(0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(user.username.prefix(1)).uppercased())
                                        .font(.title3.bold())
                                        .foregroundStyle(Color.sparkBlue)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.headline)
                                Text("\(myPosts.count) post\(myPosts.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }

                    if !myPosts.isEmpty {
                        Section("Your Posts") {
                            ForEach(myPosts) { post in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(post.title)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(2)
                                        HStack {
                                            CategoryBadge(category: post.category)
                                            Spacer()
                                            Label("\(post.score)", systemImage: "arrow.up")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        postToDelete = post
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                    .help("Delete post")
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            appState.logout()
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            confirmingDeleteAccount = true
                        } label: {
                            Label("Delete Account", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Not signed in")
                        .font(.headline)
                    Button("Sign In / Register") {
                        appState.showAuth = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .tint(.sparkBlue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Profile")
        .confirmationDialog(
            "Delete post?",
            isPresented: Binding(
                get: { postToDelete != nil },
                set: { if !$0 { postToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let post = postToDelete else { return }
                Task {
                    do {
                        try await appState.deletePost(id: post.id)
                    } catch {
                        appState.errorBanner = error.localizedDescription
                    }
                }
                postToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                postToDelete = nil
            }
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $confirmingDeleteAccount,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task { _ = await appState.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account. This cannot be undone.")
        }
    }
}
