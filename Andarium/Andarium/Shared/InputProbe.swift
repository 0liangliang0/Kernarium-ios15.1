import Combine
// SPDX-License-Identifier: GPL-2.0-or-later


/// A UI test's window on the guest's keyboard and mouse. The UI tests drive
/// the real application in the Simulator with synthetic keys and pointer
/// events and cannot see the runtime, so a launch that asks for the probe
/// (`ANDARIUM_INPUT_PROBE`, `LaunchEnvironment.swift`) sends what the guest
/// would receive to this log, which the session shows as one accessibility
/// element, and gives Settings a text field to prove that a sheet keeps the
/// keys it takes.
final class InputProbe: ObservableObject {

    /// The newest lines last.
    @Published private(set) var lines: [String] = []
    /// The text field in Settings.
    @Published var fieldText = ""

    static let capacity = 400

    func record(_ line: String) {
        lines.append(line)
        if lines.count > Self.capacity { lines.removeFirst(lines.count - Self.capacity) }
    }

    var text: String { lines.joined(separator: "\n") }
}
