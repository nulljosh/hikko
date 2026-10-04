import WidgetKit
import SwiftUI

struct NewPostsWidget: Widget {
    let kind = "NewPostsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewPostsProvider()) { entry in
            NewPostsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("New Posts")
        .description("Latest ideas shared on Hikko.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct NewPostsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NewPostsEntry

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
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.sparkBlue)
                Text("New")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let latest = entry.posts.first {
                Text(latest.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                Text(latest.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.sparkBlue)
                Text("New Posts")
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
                    Text(post.relativeTime)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
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
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.sparkBlue)
                Text("New Posts")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(Array(entry.posts.prefix(3).enumerated()), id: \.element.id) { index, post in
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color.sparkBlue)
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)

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

                    Text(post.relativeTime)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
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
