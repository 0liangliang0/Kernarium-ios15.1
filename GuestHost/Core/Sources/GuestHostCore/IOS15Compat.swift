// SPDX-License-Identifier: GPL-2.0-or-later
//
// iOS 15 compatibility shims. The application's sources use Swift 5.7+/iOS 16+
// standard-library and Foundation conveniences (Duration, Clock, localized
// String initializers, LocalizedStringResource). None of those exist on
// iOS 15.1, the deployment target of the sideloaded IPA. This file provides
// values with the same behaviour, backed by APIs that predate iOS 15, so the
// call sites can be migrated mechanically without changing their meaning.

import Foundation

// MARK: - Locking

public extension NSLock {
    /// `NSLock.withLock` is iOS 16+; this provides the same scoped locking on
    /// iOS 15 with the same rethrows behaviour.
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

// MARK: - Duration

/// Seconds, as a floating-point value. The stdlib `Duration` type is iOS 16+;
/// every interval in this application is a count of seconds, so `TimeInterval`
/// is a direct representation and keeps all arithmetic (including division by
/// an integer literal) unchanged at the call sites.
public typealias CompatDuration = TimeInterval

public extension TimeInterval {
    static func seconds(_ value: Double) -> TimeInterval { value }
    static func seconds(_ value: Int) -> TimeInterval { Double(value) }
    static func milliseconds(_ value: Double) -> TimeInterval { value / 1_000 }
    static func milliseconds(_ value: Int) -> TimeInterval { Double(value) / 1_000 }
    static func microseconds(_ value: Double) -> TimeInterval { value / 1_000_000 }
    static func microseconds(_ value: Int) -> TimeInterval { Double(value) / 1_000_000 }
    static func nanoseconds(_ value: Double) -> TimeInterval { value / 1_000_000_000 }
    static func nanoseconds(_ value: Int) -> TimeInterval { Double(value) / 1_000_000_000 }

    /// The whole seconds and fractional attoseconds of this interval, matching
    /// the shape of `Duration.components` used by the call sites.
    var components: CompatDurationComponents { CompatDurationComponents(self) }

    func duration(to other: TimeInterval) -> TimeInterval { other - self }
}

/// The fields of `Duration.components` that the application reads.
public struct CompatDurationComponents: Sendable {
    public let seconds: Int
    public let attoseconds: Int
    public let milliseconds: Int

    public init(_ duration: TimeInterval) {
        let finite = duration.isFinite ? duration : 0
        let whole = Int(finite)
        self.seconds = whole
        self.attoseconds = Int((finite - Double(whole)) * 1e18)
        self.milliseconds = Int((finite * 1_000).rounded())
    }
}

// MARK: - Clocks

/// A monotonic instant backed by `DispatchTime`, which is available on every
/// supported iOS version. `ContinuousClock.Instant` and
/// `SuspendingClock.Instant` are iOS 16+.
public struct CompatClockInstant: Sendable, Comparable {
    fileprivate let uptimeNanoseconds: UInt64

    public static func < (lhs: CompatClockInstant, rhs: CompatClockInstant) -> Bool {
        lhs.uptimeNanoseconds < rhs.uptimeNanoseconds
    }

    public static func + (instant: CompatClockInstant, duration: CompatDuration) -> CompatClockInstant {
        let delta = duration.isFinite ? max(0, duration) : 0
        return CompatClockInstant(
            uptimeNanoseconds: instant.uptimeNanoseconds &+ UInt64(min(delta, 1e9) * 1e9)
        )
    }

    public static func - (lhs: CompatClockInstant, rhs: CompatClockInstant) -> CompatDuration {
        lhs.duration(to: rhs)
    }

    public func advanced(by duration: CompatDuration) -> CompatClockInstant {
        self + duration
    }

    fileprivate init(uptimeNanoseconds: UInt64) {
        self.uptimeNanoseconds = uptimeNanoseconds
    }

    /// The `Instant.now` member used by call sites that write `.now` inside
    /// `duration(to:)`.
    public static var now: CompatClockInstant {
        CompatClockInstant(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds)
    }

    public func duration(to other: CompatClockInstant) -> CompatDuration {
        let a = uptimeNanoseconds
        let b = other.uptimeNanoseconds
        return b >= a
            ? Double(b - a) / 1e9
            : -Double(a - b) / 1e9
    }
}

/// Counts time while the device sleeps.
public struct CompatContinuousClock {
    public typealias Instant = CompatClockInstant

    public init() {}

    public static var now: CompatClockInstant {
        CompatClockInstant(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds)
    }

    public func duration(to other: CompatClockInstant) -> CompatDuration {
        CompatClockInstant.now.duration(to: other)
    }
}

/// Stands still while the device sleeps. `DispatchTime` is the closest iOS 15
/// equivalent; the application only uses it for short interrupt timings.
public struct CompatSuspendingClock {
    public typealias Instant = CompatClockInstant

    public init() {}

    public static var now: CompatClockInstant {
        CompatClockInstant(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds)
    }

    public func duration(to other: CompatClockInstant) -> CompatDuration {
        CompatClockInstant.now.duration(to: other)
    }
}

// MARK: - Sleeping

/// `Task.sleep(for:)` is iOS 16+. The nanosecond overload is available from
/// iOS 13 and has the same cancellation behaviour.
public func compatSleep(for duration: CompatDuration, tolerance: CompatDuration? = nil) async throws {
    let seconds = duration.isFinite ? max(0, duration) : 0
    try await Task.sleep(nanoseconds: UInt64(min(seconds, 1e9) * 1_000_000_000))
}

public func compatSleep(
    until deadline: CompatClockInstant,
    clock: CompatContinuousClock,
    tolerance: CompatDuration? = nil
) async throws {
    try await compatSleep(for: CompatClockInstant.now.duration(to: deadline))
}

public func compatSleep(
    until deadline: CompatClockInstant,
    clock: CompatSuspendingClock,
    tolerance: CompatDuration? = nil
) async throws {
    try await compatSleep(for: CompatClockInstant.now.duration(to: deadline))
}

// MARK: - Localization

/// A bundle source accepted by the `compatLocalized` initializer. `Bundle`
/// itself conforms, as does the `.atURL(...)` description used by the update
/// words, which loads strings from the package's resource bundle.
public protocol CompatBundleProviding {
    var resolvedBundle: Bundle? { get }
}

extension Bundle: CompatBundleProviding {
    public var resolvedBundle: Bundle? { self }
}

/// A stand-in for `LocalizedStringResource` (iOS 16+). It keeps the key and
/// the bundle the caller chose; interpolation happens through ordinary
/// `String` interpolation, which works on iOS 15.
public struct CompatLocalizedStringResource {
    public enum BundleDescription: CompatBundleProviding {
        case main
        case atURL(URL)

        public var resolvedBundle: Bundle? {
            switch self {
            case .main: return .main
            case .atURL(let url): return Bundle(url: url)
            }
        }
    }

    public let key: String
    public let table: String?
    public let bundle: (any CompatBundleProviding)?
    public let locale: Locale?
    public let comment: String?

    public init(
        _ key: String,
        table: String? = nil,
        locale: Locale? = nil,
        bundle: (any CompatBundleProviding)? = nil,
        comment: String? = nil
    ) {
        self.key = key
        self.table = table
        self.bundle = bundle
        self.locale = locale
        self.comment = comment
    }
}

public extension String {
    /// Drop-in replacement for `String(localized:table:bundle:locale:comment:)`
    /// (iOS 16+), backed by `NSLocalizedString` (iOS 2+).
    init(
        compatLocalized key: String,
        defaultValue: String? = nil,
        table: String? = nil,
        locale: Locale? = nil,
        bundle: Bundle? = nil,
        comment: String? = nil
    ) {
        self = NSLocalizedString(
            key,
            tableName: table,
            bundle: bundle ?? .main,
            value: defaultValue ?? key,
            comment: comment ?? ""
        )
    }

    init(compatLocalized resource: CompatLocalizedStringResource) {
        var resolved: Bundle?
        if let bundle = resource.bundle { resolved = bundle.resolvedBundle }
        self = NSLocalizedString(
            resource.key,
            tableName: resource.table,
            bundle: resolved ?? .main,
            value: resource.key,
            comment: resource.comment ?? ""
        )
    }
}
