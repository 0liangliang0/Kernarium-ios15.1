// SPDX-License-Identifier: GPL-2.0-or-later
//
// SwiftUI views introduced after iOS 15, rebuilt with iOS 15 primitives. This
// file is compiled into the Andarium target (GuestHost/Sources is a source
// folder of that target), so it is visible to both GuestHost and Andarium
// sources.

import Combine
import SwiftUI
import GuestHostCore

/// The iOS 17 `@Environment(AppModel.self)` reader has no iOS 15 equivalent.
/// An optional environment value covers the places that deliberately accept
/// no model in the environment.
private struct CompatAppModelKey: EnvironmentKey {
    static let defaultValue: AppModel? = nil
}

extension EnvironmentValues {
    var compatAppModel: AppModel? {
        get { self[CompatAppModelKey.self] }
        set { self[CompatAppModelKey.self] = newValue }
    }
}

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

/// Stand-in for `GlassEffectContainer` (iOS 26+). iOS 15 has no glass
/// material; the children keep their own layouts and backgrounds.
public struct CompatGlassEffectContainer<Content: View>: View {
    private let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View { content }
}

// MARK: - iOS 16 view types

/// Stand-in for `ViewThatFits` (iOS 16+). iOS 15 has no way to measure and
/// choose among alternatives inside a `ViewBuilder`, so the first layout is
/// used; the alternative remains in the source for a later, richer shim.
public struct CompatViewThatFits<Content: View>: View {
    private let content: Content

    public init(in axis: Axis.Set = [.horizontal, .vertical], @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View { content }
}

/// Stand-in for `UnevenRoundedRectangle` (iOS 16+) with the same four corner
/// radii. The path is drawn with per-corner arcs, so it works on iOS 15.
public struct CompatUnevenRoundedRectangle: Shape {
    public var topLeadingRadius: CGFloat = 0
    public var topTrailingRadius: CGFloat = 0
    public var bottomLeadingRadius: CGFloat = 0
    public var bottomTrailingRadius: CGFloat = 0
    public var style: RoundedCornerStyle = .continuous

    public init(
        topLeadingRadius: CGFloat = 0,
        bottomLeadingRadius: CGFloat = 0,
        bottomTrailingRadius: CGFloat = 0,
        topTrailingRadius: CGFloat = 0,
        style: RoundedCornerStyle = .continuous
    ) {
        self.topLeadingRadius = topLeadingRadius
        self.bottomLeadingRadius = bottomLeadingRadius
        self.bottomTrailingRadius = bottomTrailingRadius
        self.topTrailingRadius = topTrailingRadius
        self.style = style
    }

    public func path(in rect: CGRect) -> Path {
        let tl = min(topLeadingRadius, min(rect.width, rect.height) / 2)
        let tr = min(topTrailingRadius, min(rect.width, rect.height) / 2)
        let bl = min(bottomLeadingRadius, min(rect.width, rect.height) / 2)
        let br = min(bottomTrailingRadius, min(rect.width, rect.height) / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                    tangent2End: CGPoint(x: rect.maxX, y: rect.minY + tr), radius: tr)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.maxX - br, y: rect.maxY), radius: br)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bl), radius: bl)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                    tangent2End: CGPoint(x: rect.minX + tl, y: rect.minY), radius: tl)
        path.closeSubpath()
        return path
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
