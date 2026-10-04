import SwiftUI

struct CreateView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedItem: SidebarItem

    @State private var title = ""
    @State private var content = ""
    @State private var category = "General"
    @State private var linkedRepo = ""
    @State private var autoEnrich = true
    @State private var isPosting = false
    @State private var errorMsg: String?
    @State private var showSuccess = false

    let categories = ["General", "Tech", "Science", "Art", "Business", "Other"]

    var body: some View {
        if !appState.isLoggedIn {
            VStack(spacing: 12) {
                Image(systemName: "lock")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Sign in to post")
                    .font(.headline)
                Text("Create an account or log in to share ideas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Sign In") {
                    appState.showAuth = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .tint(.sparkBlue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                Section("Idea") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextEditor(text: $content)
                        .font(.body)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))

                    HStack {
                        Spacer()
                        Text("\(content.count)/500")
                            .font(.caption)
                            .foregroundStyle(content.count > 500 ? .red : .secondary)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                Section("Options") {
                    TextField("Repo URL (optional)", text: $linkedRepo)
                        .textFieldStyle(.roundedBorder)
                    Toggle("Request AI write-up", isOn: $autoEnrich)
                }

                if let err = errorMsg {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Button(action: post) {
                            if isPosting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Post")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .tint(.sparkBlue)
                        .controlSize(.large)
                        .disabled(!canPost)
                        .keyboardShortcut(.return, modifiers: .command)
                        Spacer()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create")
            .alert("Posted!", isPresented: $showSuccess) {
                Button("OK") { selectedItem = .feed }
            }
            .padding()
        }
    }

    private var canPost: Bool {
        appState.isLoggedIn && !title.trimmingCharacters(in: .whitespaces).isEmpty &&
            !content.trimmingCharacters(in: .whitespaces).isEmpty && content.count <= 500 && !isPosting
    }

    private func post() {
        isPosting = true
        errorMsg = nil
        Task {
            do {
                let repo = linkedRepo.trimmingCharacters(in: .whitespaces)
                let post = try await appState.createPost(
                    title: title, content: content, category: category,
                    linkedRepo: repo.isEmpty ? nil : repo
                )
                if autoEnrich {
                    await appState.requestEnrichment(postId: post.id)
                }
                title = ""
                content = ""
                category = "General"
                linkedRepo = ""
                showSuccess = true
            } catch {
                errorMsg = error.localizedDescription
            }
            isPosting = false
        }
    }
}
