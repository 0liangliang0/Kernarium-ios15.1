// SPDX-License-Identifier: GPL-2.0-or-later

import AndariumCore
import UIKit

/// Reads the folding display's hinge and reserved regions. Those UIKit types
/// exist only from iOS 27.1; an iOS 15 device has no folding display to read,
/// so this port keeps the same interface and always reports no hinge. A test
/// can still supply a reading through `stub`.
@MainActor
final class FoldSceneReader {
    var hingeDidChange: (() -> Void)?
    var stub: (@MainActor () -> FoldReading?)?

    var reportsHinge: Bool { false }

    func attach(to view: UIView) {}

    func read(_ view: UIView) -> FoldReading? { stub?() }
}
