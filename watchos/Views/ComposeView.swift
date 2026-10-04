import SwiftUI

struct ComposeView: View {
    @State private var title = ""
    @State private var content = ""
    @State private var isPosting = false
    @State private var showSuccess = false
    @State private var errorMsg: String?

    private var canPost: Bool {
        WatchAPI.shared.isLoggedIn &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isPosting
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.sparkBlue)
                    Text("NEW IDEA")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                if !WatchAPI.shared.isLoggedIn {
                    VStack(spacing: 4) {
                        Image(systemName: "lock")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Sign in to post")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                } else if showSuccess {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.sparkBlue)
                        Text("Posted!")
                            .font(.caption.bold())
                        Button("New Idea") {
                            showSuccess = false
                        }
                        .font(.caption2)
                        .tint(Color.sparkBlue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                } else {
                    TextField("Title", text: $title)
                        .font(.caption)

                    TextField("Your idea...", text: $content)
                        .font(.caption)

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await post() }
                    } label: {
                        if isPosting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Post")
                            }
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.sparkBlue)
                    .foregroundStyle(Color(red: 0.11, green: 0.10, blue: 0.09))
                    .disabled(!canPost)
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func post() async {
        isPosting = true
        errorMsg = nil
        do {
            _ = try await WatchAPI.shared.createPost(
                title: title.trimmingCharacters(in: .whitespaces),
                content: content.trimmingCharacters(in: .whitespaces),
                category: "General"
            )
            title = ""
            content = ""
            showSuccess = true
        } catch {
            errorMsg = "Failed to post"
        }
        isPosting = false
    }
}
