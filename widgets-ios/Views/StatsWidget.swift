import WidgetKit
import SwiftUI

struct StatsWidget: Widget {
    let kind = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hikko Stats")
        .description("Post counts at a glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

struct StatsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: StatsEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryInline:
            accessoryInlineView
        case .systemSmall:
            smallView
        default:
            smallView
        }
    }

    // MARK: - Lock Screen

    private var accessoryCircularView: some View {
        VStack(spacing: 1) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
            Text("\(entry.stats.totalPosts)")
                .font(.caption2.bold())
            Text("posts")
                .font(.system(size: 8))
        }
    }

    private var accessoryInlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "lightbulb.fill")
            Text("\(entry.stats.totalPosts) posts")
        }
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.sparkBlue)
                Text("Stats")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.stats.totalPosts)")
                        .font(.title.bold())
                    Text("total posts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.stats.yourPosts)")
                        .font(.title2.bold())
                        .foregroundStyle(Color.sparkBlue)
                    Text("your posts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}
