// SPDX-License-Identifier: GPL-2.0-or-later

import AndariumCore
import Foundation

/// The words of Add to Home Screen. "Android" and "virtual machine", never
/// "VM" or "guest". Apple's names keep Apple's capitals (Home Screen,
/// Shortcuts, Add to Home Screen); an app's own name is shown as Android
/// gives it, between quotation marks.
nonisolated enum AndroidAppsWords {
    /// The feature's name, which is also the label of the command Apple's
    /// Shortcuts shows for an icon (the guide names that command too).
    static let featureName = String(compatLocalized: "Add to Home Screen")
    /// What the Settings row says beside its name.
    static let rowDetail = String(compatLocalized: "Shortcuts")

    // MARK: Choosing an app

    static let searchPrompt = String(compatLocalized: "Search Android apps")
    static let installed = String(compatLocalized: "Installed")
    static let builtIn = String(compatLocalized: "Built into Android")
    static let refreshing = String(compatLocalized: "Reading apps from Android\u{2026}")
    static let tryAgain = String(compatLocalized: "Try again")
    static let emptyTitle = String(compatLocalized: "No Android apps yet")
    static let failedTitle = String(compatLocalized: "Couldn\u{2019}t read Android\u{2019}s apps")
    static let emptyText = String(compatLocalized: "Android has no app with an icon to add.")
    static let noResultsText = String(compatLocalized: "No app in Android has this name.")
    static let searchSwitch = String(compatLocalized: "Show in Search")
    static let searchFooter = String(compatLocalized: "Android apps appear in Search while this is on. They stay available in Shortcuts and Siri when it\u{2019}s off.")

    static func noResults(_ query: String) -> String {
        String(compatLocalized: "No Results for \u{201C}\(query)\u{201D}")
    }

    /// The note under a list that is the last one Android gave, when Android
    /// did not answer this time.
    static func remembered(_ date: String) -> String {
        String(compatLocalized: "Android didn\u{2019}t answer. Showing the list from \(date).")
    }

    /// What VoiceOver reads for an app of the list: the command it leads to.
    static func addLabel(_ app: String) -> String {
        String(compatLocalized: "Add \u{201C}\(app)\u{201D} to Home Screen")
    }

    // MARK: Adding one app

    static let androidApp = String(compatLocalized: "Android app")
    static let inShortcuts = String(compatLocalized: "In the Shortcuts app")
    static let step1 = String(compatLocalized: "Open Shortcuts")
    static let step1Detail = String(compatLocalized: "It opens on Andarium\u{2019}s page.")
    static let step2Detail = String(compatLocalized: "Its tile has the app\u{2019}s own icon.")
    static let step3 = String(compatLocalized: "Tap Add to Home Screen")
    static let step3Detail = String(compatLocalized: "The icon and name are already filled in.")
    static let step4 = String(compatLocalized: "Tap the check mark")
    static let step4Detail = String(compatLocalized: "The icon appears on your Home Screen.")
    static let linkCaption = String(compatLocalized: "Opens Andarium\u{2019}s page in Shortcuts.")

    static func step2(_ app: String) -> String {
        String(compatLocalized: "Touch and hold \u{201C}\(app)\u{201D}")
    }

    static func tapNote(_ app: String) -> String {
        String(compatLocalized: "A tap on the icon opens \u{201C}\(app)\u{201D} in Android, and starts Android first if it isn\u{2019}t running.")
    }

    /// The words of Apple's screens, only drawn in the guide: the command the
    /// App Intent gives the first tile, the menu of a held tile and the title
    /// of the sheet that adds the icon.
    static let intentTile = String(compatLocalized: "Open Android App")
    static let menuAdd = String(compatLocalized: "Add to Home Screen")
    static let menuNewShortcut = String(compatLocalized: "New Shortcut")
    static let sheetTitle = String(compatLocalized: "Home Screen")

    // MARK: Waiting for Android

    static let openingDetail = String(compatLocalized: "It opens as soon as Android has started.")
    static let dontOpen = String(compatLocalized: "Don\u{2019}t open")
    static let waitingUpdateText = String(compatLocalized: "Choose what to do with the unfinished update below. The app opens once Android has started.")

    static func openingTitle(_ app: String) -> String {
        String(compatLocalized: "Opening \u{201C}\(app)\u{201D}")
    }

    static func openingPill(_ app: String) -> String {
        String(compatLocalized: "Opening \u{201C}\(app)\u{201D}\u{2026}")
    }

    static func waitingUpdateTitle(_ app: String) -> String {
        String(compatLocalized: "\u{201C}\(app)\u{201D} is waiting")
    }

    static func waitingSpaceTitle(_ app: String) -> String {
        String(compatLocalized: "\u{201C}\(app)\u{201D} is waiting for space")
    }

    static func waitingSpaceText(device: String) -> String {
        String(compatLocalized: "Free up space on this \(device), then tap Start. The app opens once Android has started.")
    }

    // MARK: When it cannot open

    static let notInAndroidText = String(compatLocalized: "It may have been removed from Android. You can remove its icon from the Home Screen.")
    static let tookTooLongText = String(compatLocalized: "Android took too long. Try again, or open it from Android\u{2019}s home screen.")
    static let recoveryTitle = String(compatLocalized: "Android is in recovery mode")
    static let setupTitle = String(compatLocalized: "Android is still being set up")
    static let noAndroidText = String(compatLocalized: "There is no virtual machine. The icon works again once the app is installed in a new virtual machine.")
    static let dismiss = String(compatLocalized: "Dismiss")

    static func notInAndroidTitle(_ app: String) -> String {
        String(compatLocalized: "\u{201C}\(app)\u{201D} isn\u{2019}t in Android")
    }

    static func tookTooLongTitle(_ app: String) -> String {
        String(compatLocalized: "\u{201C}\(app)\u{201D} didn\u{2019}t open")
    }

    static func setupText(_ app: String) -> String {
        String(compatLocalized: "Finish setting up Android, then open \u{201C}\(app)\u{201D} again.")
    }

    static func toolMissingTitle(_ app: String) -> String {
        String(compatLocalized: "Can\u{2019}t open \u{201C}\(app)\u{201D}")
    }

    static let toolMissingText = String(compatLocalized: "This version of Android is too old to open apps directly. Update Andarium, then open the app again.")

    static func recoveryText(_ app: String) -> String {
        String(compatLocalized: "Restart Android normally to open \u{201C}\(app)\u{201D}.")
    }

    /// The banner's title and text for a failure.
    static func banner(_ failure: AppOpenFailure, app: String) -> (title: String, text: String) {
        switch failure {
        case .notInAndroid: (notInAndroidTitle(app), notInAndroidText)
        case .tookTooLong: (tookTooLongTitle(app), tookTooLongText)
        case .recovery: (recoveryTitle, recoveryText(app))
        case .setupUnfinished: (setupTitle, setupText(app))
        case .toolMissing: (toolMissingTitle(app), toolMissingText)
        }
    }
}
