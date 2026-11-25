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
    /// The last value written for each setting. The model publishes every one
    /// of its fields, so a change to any field re-runs `keep`; without these
    /// marks that turns one tap into writes of all eight settings on the main
    /// thread, and a burst of start-up changes into hundreds of writes. A
    /// mark is only a short-circuit for a value already stored: the writer
    /// still runs for every change, so a launch that decides a value (and so
    /// publishes `nil`) leaves what the person stored alone.
    private var keptDisplayOptions: DisplayOptions?
    private var keptShowStats: Bool?
    private var keptPointerAsTouch: Bool?
    private var keptHeatLimit: Bool?
    private var keptHighRefresh: Bool?
    private var keptTranslatedLibraries: Bool?
    private var keptJit: Bool?

    init(model: AppModel, defaults: UserDefaults = .standard) {
        self.model = model
        self.defaults = defaults
    }

    func start() {
        observe()
    }

    /// Writes what the model says is the person's, and only what has changed.
    func keep() {
        guard let model else { return }
        if let options = model.displayOptionsToKeep, options != keptDisplayOptions {
            DisplayOptionsStore.save(options, to: defaults)
            keptDisplayOptions = options
        }
        if let on = model.showStatsToKeep, on != keptShowStats {
            StatsPreference(defaults: defaults).keep(on)
            keptShowStats = on
        }
        if let on = model.pointerAsTouchToKeep, on != keptPointerAsTouch {
            PointerPreference(defaults: defaults).keep(on)
            keptPointerAsTouch = on
        }
        if let on = model.heatLimitToKeep, on != keptHeatLimit {
            HeatLimitPreference(defaults: defaults).keep(on)
            keptHeatLimit = on
        }
        if let on = model.highRefreshToKeep, on != keptHighRefresh {
            HighRefreshPreference(defaults: defaults).keep(on)
            keptHighRefresh = on
        }
        if let on = model.translatedLibrariesToKeep, on != keptTranslatedLibraries {
            TranslatedLibrariesPreference(defaults: defaults).keep(on)
            keptTranslatedLibraries = on
        }
        if let on = model.jitToKeep, on != keptJit {
            JitPreference(defaults: defaults).keep(on)
            keptJit = on
        }
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
