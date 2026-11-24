// SPDX-License-Identifier: GPL-2.0-or-later
//
// SwiftUI views introduced after iOS 15, rebuilt with iOS 15 primitives. This
// file is compiled into the Andarium target (GuestHost/Sources is a source
// folder of that target), so it is visible to both GuestHost and Andarium
// sources.

import SwiftUI
import GuestHostCore

// MARK: - Rounded rectangle shorthand

public extension Shape where Self == RoundedRectangle {
    /// Stand-in for `ShapeStyle.rect(cornerRadius:style:)` (iOS 16+).
    static func compatRect(
        cornerRadius: CGFloat,
        style: RoundedCornerStyle = .continuous
    ) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: style)
    }
}

// MARK: - LabeledContent

/// A two-column row, equivalent to `LabeledContent` (iOS 16+).
public struct CompatLabeledContent: View {
    private let label: AnyView
    private let content: AnyView

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            label
            Spacer(minLength: 8)
            content
        }
    }

    public init<L: View, C: View>(@ViewBuilder content: () -> C, @ViewBuilder label: () -> L) {
        self.label = AnyView(label())
        self.content = AnyView(content())
    }

    public init<C: View>(_ title: String, @ViewBuilder content: () -> C) {
        self.label = AnyView(Text(title))
        self.content = AnyView(content())
    }

    public init(_ title: String, value: String) {
        self.label = AnyView(Text(title))
        self.content = AnyView(Text(value))
    }
}

// MARK: - ContentUnavailableView

/// The empty-state layout of `ContentUnavailableView` (iOS 17+), using only
/// iOS 15 views.
public struct CompatContentUnavailableView: View {
    private let label: AnyView
    private let description: AnyView?
    private let actions: AnyView?

    public var body: some View {
        VStack(spacing: 12) {
            label
            description
            actions
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    public init<L: View, D: View>(
        @ViewBuilder label: () -> L,
        @ViewBuilder description: () -> D
    ) {
        self.label = AnyView(label())
        self.description = AnyView(description())
        self.actions = nil
    }

    public init<L: View, D: View, A: View>(
        @ViewBuilder label: () -> L,
        @ViewBuilder description: () -> D,
        @ViewBuilder actions: () -> A
    ) {
        self.label = AnyView(label())
        self.description = AnyView(description())
        self.actions = AnyView(actions())
    }

    public init(_ title: String, systemImage: String) {
        self.label = AnyView(
            VStack(spacing: 8) {
                Image(systemName: systemImage).font(.largeTitle)
                Text(title).font(.title2).fontWeight(.semibold)
            }
        )
        self.description = nil
        self.actions = nil
    }
}

// MARK: - Value-based navigation

/// Routes sent by `CompatNavigationLink` are delivered to the nearest
/// `compatNavigationDestination(for:)` registered for the same value type.
/// `NavigationStack`'s value path (iOS 16+) is replaced by a sheet presentation
/// of the destination view, which keeps the destination reachable on iOS 15.
public final class CompatNavigationRouter {
    public static let shared = CompatNavigationRouter()

    private var handlers: [(Any) -> Bool] = []
    private var tokens = Set<UUID>()

    public func register(_ token: UUID, _ handler: @escaping (Any) -> Bool) {
        if tokens.insert(token).inserted {
            handlers.append(handler)
        }
    }

    public func send(_ value: Any) {
        for handler in handlers where handler(value) { return }
    }
}

private struct CompatPresentedView: Identifiable {
    let id = UUID()
    let view: AnyView
}

private final class CompatDestinationState: ObservableObject {
    @Published var item: CompatPresentedView?
}

private struct CompatNavigationDestinationModifier<D, Destination: View>: ViewModifier {
    @StateObject private var state = CompatDestinationState()
    @State private var token = UUID()
    let destination: (D) -> Destination

    func body(content: Content) -> some View {
        // Capture the underlying object, not the property wrapper, so the
        // escaping registration closure does not capture a mutating `self`.
        let holder = state
        CompatNavigationRouter.shared.register(token) { value in
            guard let typed = value as? D else { return false }
            holder.item = CompatPresentedView(view: AnyView(destination(typed)))
            return true
        }
        return AnyView(content.sheet(item: $state.item) { $0.view })
    }
}

public extension View {
    func compatNavigationDestination<D, Destination: View>(
        for: D.Type,
        @ViewBuilder destination: @escaping (D) -> Destination
    ) -> some View {
        modifier(CompatNavigationDestinationModifier(destination: destination))
    }
}

public struct CompatNavigationLink<Label: View>: View {
    private let value: Any
    private let label: Label

    public init(value: Any, @ViewBuilder label: () -> Label) {
        self.value = value
        self.label = label()
    }

    public init(value: Any, label: Label) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        Button { CompatNavigationRouter.shared.send(value) } label: { label }
    }
}
