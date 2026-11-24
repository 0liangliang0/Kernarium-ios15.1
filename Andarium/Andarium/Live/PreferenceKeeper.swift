// SPDX-License-Identifier: GPL-2.0-or-later

import AndariumCore
import Combine
import Foundation

/// Keeps what the person sets across launches: Home's "120 Hz", AOT and JIT
/// rows, the display options chosen on Home, and Settings' "Show on screen",
/// "Use the pointer as touch" and "When hot". Each is written when it changes. A
/// value the launch decided for its own run is not written, so a harness
/// launch never replaces what the person stored (`AppModel.displayOptionsToKeep`,
/// `showStatsToKeep`).
final class PreferenceKeeper {
    private weak var model: AppModel?
    private let defaults: UserDefaults
    /// The write an observed change has queued, which re-arms the observation
    /// when it ends; a test awaits it.
    private(set) var pending: Task<Void, Never>?
    private var cancellable: AnyCancellable?

    init(model: AppModel, defaults: UserDefaults = .standard) {
        self.model = model
        self.defaults = defaults
    }

    func start() {
        observe()
    }

    /// Writes what the model says is the person's.
    func keep() {
        guard let model else { return }
        if let options = model.displayOptionsToKeep { DisplayOptionsStore.save(options, to: defaults) }
        if let on = model.showStatsToKeep { StatsPreference(defaults: defaults).keep(on) }
        if let on = model.pointerAsTouchToKeep { PointerPreference(defaults: defaults).keep(on) }
        if let on = model.heatLimitToKeep { HeatLimitPreference(defaults: defaults).keep(on) }
        if let on = model.highRefreshToKeep { HighRefreshPreference(defaults: defaults).keep(on) }
        if let on = model.translatedLibrariesToKeep { TranslatedLibrariesPreference(defaults: defaults).keep(on) }
        if let on = model.jitToKeep { JitPreference(defaults: defaults).keep(on) }
    }

    /// The Observation framework is absent on iOS 15. The model is an
    /// `ObservableObject`, so its publisher carries the same change signal.
    private func observe() {
        guard let model else { return }
        cancellable = model.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.pending = Task { @MainActor [weak self] in self?.keep() }
            }
    }
}
