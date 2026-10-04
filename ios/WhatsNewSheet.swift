import SwiftUI

private let whatsNewVersion = "3.0"
private let whatsNewRows: [(icon: String, text: String)] = [
    ("sparkles", "Sparkjar is now Hotaru. Same jar, new light."),
    ("bell", "Today's idea, every morning at nine."),
    ("square.grid.2x2", "Categories with icons, and a calmer feed."),
    ("paintpalette", "One palette across iPhone, Mac and the web."),
]

struct WhatsNewSheet: View {
    @AppStorage("whats_new_seen_version") private var seenVersion = ""
    @State private var isPresented = false

    var body: some View {
        Color.clear
            .task {
                // Wait for the splash to fade before showing anything.
                try? await Task.sleep(for: .seconds(1.6))
                isPresented = seenVersion != whatsNewVersion
            }
            .sheet(isPresented: $isPresented) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("New in Hotaru \(whatsNewVersion)")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(whatsNewRows, id: \.text) { row in
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Image(systemName: row.icon)
                                    .foregroundStyle(Color.sparkBlue)
                                    .frame(width: 22)
                                Text(row.text)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Button {
                        seenVersion = whatsNewVersion
                        isPresented = false
                    } label: {
                        Text("Got it")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .controlSize(.large)
                    .tint(.sparkBlue)
                }
                .padding(.horizontal, 28)
                .padding(.top, 36)
                .padding(.bottom, 24)
                .frame(maxHeight: .infinity, alignment: .top)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
    }
}
