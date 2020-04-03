import SwiftUI

struct BorderedMessageView<Model>: View where Model: MessageViewModelProtocol {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.sizeCategory) var sizeCategory: ContentSizeCategory
    @Environment(\.userId) var userId

    var model: Model
    var connectedEdges: ConnectedEdges

    private var isMe: Bool {
        model.sender == userId
    }

    var textColor: Color {
        guard model.sender == userId else {
            return .primary
        }
        return .white
    }

    var backgroundColor: Color {
        guard model.sender == userId else {
            return .borderedMessageBackground
        }
        return .accentColor
    }

    var gradient: LinearGradient {
        let color: Color = backgroundColor
        let colors: [Color]
        if colorScheme == .dark {
            colors = [color.opacity(1.0), color.opacity(0.85)]
        } else {
            colors = [color.opacity(0.85), color.opacity(1.0)]
        }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var background: some View {
        let largeRadius: CGFloat = 15.0 * sizeCategory.scalingFactor
        let smallRadius: CGFloat = 5.0 * sizeCategory.scalingFactor

        // We construct a left-aligned shape:
        return IndividuallyRoundedRectangle(
            topLeft: connectedEdges.contains(.topEdge) ? smallRadius : largeRadius,
            topRight: largeRadius,
            bottomLeft: connectedEdges.contains(.bottomEdge) ? smallRadius : largeRadius,
            bottomRight: largeRadius
        )
            .fill(gradient).opacity(0.9)
            // and flip it in case it's meant to be right-aligned:
            .scaleEffect(x: isMe ? -1.0 : 1.0, y: 1.0, anchor: .center)
    }

    var bodyView: some View {
        Text(model.text)
            .foregroundColor(textColor)
    }

    var senderView: some View {
        if model.showSender && !isMe && connectedEdges == .bottomEdge {
            return AnyView(
                Text(model.sender)
                    .font(.caption)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    var timestampView: some View {
        Text(model.timestamp)
        .font(.caption)
        .foregroundColor(textColor).opacity(0.5)
    }

    var reactionsView: some View {
        // The conditional EmptyView here exists since SwiftUI apparently decides
        // to give space to the HStack even if it's empty, which looks awkward.
        Group {
            if model.reactions.isEmpty {
                EmptyView()
            } else {
                HStack(spacing: 3) {
                    ForEach(model.groupedReactions, id: \.0) { (emoji, count) in
                        HStack(spacing: 1) {
                            Text(emoji)
                                .font(.caption)
                            Text(String(count))
                                .foregroundColor(self.textColor)
                                .font(.callout)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(self.gradient)
                                .shadow(radius: 1)
                        )
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            senderView
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                VStack(alignment: isMe ? .trailing : .leading, spacing: 5) {
                    bodyView
                    if !connectedEdges.contains(.bottomEdge) {
                        // It's the last message in a group, so show a timestamp:
                        timestampView
                    }
                }
                .padding(10)
                .background(background)

                reactionsView
            }
        }
    }
}

struct BorderedMessageView_Previews: PreviewProvider {
    private struct MessageViewModel: MessageViewModelProtocol {
        var id: String
        var text: String
        var sender: String
        var showSender: Bool
        var timestamp: String
        var reactions: [String]
    }

    static func lone(sender: String,
                     text: String = "Lorem ipsum dolor sit amet!",
                     userId: String,
                     showSender: Bool,
                     reactions: [String]
    ) -> some View {
        BorderedMessageView(
            model: MessageViewModel(
                id: "0",
                text: text,
                sender: sender,
                showSender: showSender,
                timestamp: "12:29",
                reactions: reactions
            ),
            connectedEdges: []
        )
            .padding()
            .environment(\.userId, userId)
    }

    static func grouped(sender: String,
                        userId: String,
                        showSender: Bool,
                        reactions: [String]
    ) -> some View {
        let alignment: HorizontalAlignment = (sender == userId) ? .trailing : .leading

        return VStack(alignment: alignment, spacing: 3) {
            BorderedMessageView(
                model: MessageViewModel(
                    id: "0",
                    text: "This is a message",
                    sender: sender,
                    showSender: showSender,
                    timestamp: "12:29",
                    reactions: reactions
                ),
                connectedEdges: [.bottomEdge]
            )
            BorderedMessageView(
                model: MessageViewModel(
                    id: "0",
                    text: "that's quickly followed",
                    sender: sender,
                    showSender: showSender,
                    timestamp: "12:29",
                    reactions: reactions
                ),
                connectedEdges: [.topEdge, .bottomEdge]
            )
            BorderedMessageView(
                model: MessageViewModel(
                    id: "0",
                    text: "by some more messages.",
                    sender: sender,
                    showSender: showSender,
                    timestamp: "12:29",
                    reactions: reactions
                ),
                connectedEdges: [.topEdge]
            )
        }
        .padding()
        .environment(\.userId, userId)
    }

    static var previews: some View {
        Group {
            enumeratingColorSchemes {
                lone(sender: "John Doe",
                     text: "Lorem",
                     userId: "Jane Doe",
                     showSender: false,
                     reactions: ["💜", "💜", "👍", "🥳"])
            }
            .previewDisplayName("Incoming Lone Messages")

            enumeratingColorSchemes {
                lone(sender: "Jane Doe",
                     userId: "Jane Doe",
                     showSender: false,
                     reactions: ["❤️", "❤️", "👍", "🥳"])
            }
            .previewDisplayName("Outgoing Lone Messages")

            grouped(sender: "John Doe",
                    userId: "Jane Doe",
                    showSender: true,
                    reactions: ["❤️", "❤️", "👍", "🥳"])
            .previewDisplayName("Incoming Grouped Messages")

            grouped(sender: "Jane Doe",
                    userId: "Jane Doe",
                    showSender: false,
                    reactions: [])
            .previewDisplayName("Outgoing Grouped Messages")

            enumeratingSizeCategories {
                lone(sender: "John Doe",
                     userId: "Jane Doe",
                     showSender: false,
                     reactions: ["🚀"])
            }
            .previewDisplayName("Incoming Messages")
        }
        .accentColor(.purple)
        .previewLayout(.sizeThatFits)
    }
}
