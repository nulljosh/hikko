import SwiftUI

struct CommentsView: View {
    @Environment(AppState.self) private var appState
    let postId: String

    @State private var newComment = ""
    @State private var isPosting = false

    private var postComments: [Comment] {
        appState.comments[postId] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Text("\(postComments.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if appState.isLoggedIn {
                HStack(spacing: 8) {
                    TextField("Add a comment...", text: $newComment, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        postComment()
                    } label: {
                        if isPosting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title3)
                                .foregroundStyle(canPost ? Color.sparkBlue : Color.secondary)
                        }
                    }
                    .disabled(!canPost)
                }

                if newComment.count > 1800 {
                    Text("\(newComment.count)/2000")
                        .font(.caption2)
                        .foregroundStyle(newComment.count > 2000 ? .red : .secondary)
                }
            }

            if appState.isLoadingComments && postComments.isEmpty {
                ProgressView("Loading comments...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if postComments.isEmpty {
                Text("No comments yet. Be the first.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(postComments) { comment in
                    CommentRow(comment: comment)
                }
            }
        }
        .task {
            await appState.loadComments(postId: postId)
        }
    }

    private var canPost: Bool {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 2000 && !isPosting
    }

    private func postComment() {
        isPosting = true
        Task {
            do {
                try await appState.addComment(postId: postId, content: newComment)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                newComment = ""
            } catch {
                appState.errorBanner = error.localizedDescription
            }
            isPosting = false
        }
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.username)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                Spacer()
                if let date = comment.createdAt {
                    Text(relativeDate(date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Text(comment.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(10)
        .background(Color.paper2, in: RoundedRectangle(cornerRadius: 10))
    }

    private func relativeDate(_ iso: String) -> String {
        DateFormatting.relativeDate(iso)
    }
}
