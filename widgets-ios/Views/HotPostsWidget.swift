import WidgetKit
import SwiftUI

struct HotPostsWidget: Widget {
    let kind = "HotPostsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HotPostsProvider()) { entry in
            HotPostsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hot Posts")
        .description("Top trending ideas on Hikko.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HotPostsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: HotPostsEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            smallView
        }
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.sparkBlue)
                Text("Hot")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let top = entry.posts.first {
                Text(top.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                    Text("\(top.votes)")
                        .font(.caption.bold())
                }
                .foregroundStyle(Color.sparkBlue)
            } else {
                Text("No posts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.sparkBlue)
                Text("Hot Posts")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ForEach(entry.posts.prefix(3)) { post in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(post.category)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8))
                        Text("\(post.votes)")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(Color.sparkBlue)
                }
            }

            Spacer()
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.sparkBlue)
                Text("Hot Posts")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(Array(entry.posts.prefix(3).enumerated()), id: \.element.id) { index, post in
                HStack(alignment: .top) {
                    Text("#\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.sparkBlue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.title)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Text(post.category)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text("by \(post.author)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("\(post.votes)")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(Color.sparkBlue)
                }
                .padding(.vertical, 4)

                if index < min(entry.posts.count, 3) - 1 {
                    Divider()
                }
            }

            Spacer()
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

extension Color {
    static let sparkBlue = Color(red: 0/255, green: 113/255, blue: 227/255)
}
