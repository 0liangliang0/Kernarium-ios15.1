// SPDX-License-Identifier: GPL-2.0-or-later

import SwiftUI

/// Stand-in for SensoryFeedback (iOS 17+); feedback is implicit on iOS 15.
enum CompatSensoryFeedback { case success, warning, error, selection, impact, rigid, soft }

/// The application's own touch feedback: the click of a side key and the tick
/// of a ruler. The Haptics switch is the guest's vibrator's and does not
/// govern it. A launch that silences haptics (`HapticsLaunch`) does, because
/// the taps and drags of an automated run reach it and must not make the phone
/// vibrate. Every view plays its feedback through `interfaceFeedback`, which
/// `tests/tooling/andarium/test_interface_feedback.py` holds to.
enum InterfaceFeedback {
    /// What plays now: `feedback`, or nothing while the launch silences it. A
    /// view with no model (a preview) plays as it always did.
    static func playing(_ feedback: CompatSensoryFeedback, in model: AppModel?) -> CompatSensoryFeedback? {
        model?.interfaceFeedbackPlays == false ? nil : feedback
    }
}

private struct InterfaceFeedbackModifier<Trigger: Equatable>: ViewModifier {
    @Environment(\.compatAppModel) private var model: AppModel?
    let feedback: CompatSensoryFeedback
    let trigger: Trigger

    func body(content: Content) -> some View {
        let playing = InterfaceFeedback.playing(feedback, in: model)
        content
    }
}

extension View {
    /// `sensoryFeedback` for the application's own controls, silenced with the
    /// launch (`InterfaceFeedback`).
    func interfaceFeedback<Trigger: Equatable>(_ feedback: CompatSensoryFeedback, trigger: Trigger) -> some View {
        modifier(InterfaceFeedbackModifier(feedback: feedback, trigger: trigger))
    }
}
