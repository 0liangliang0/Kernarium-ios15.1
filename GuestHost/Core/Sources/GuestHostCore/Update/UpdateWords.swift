// SPDX-License-Identifier: GPL-2.0-or-later

import Foundation

/// Every sentence of the update notice, in the application's four languages.
/// They are the application's own: from the version file only the version,
/// the build, the day and the size are shown, formatted here and nowhere else.
/// The words live in this package's catalog (`Resources/Localizable.xcstrings`)
/// so Kernarium and Andarium say them the same way; the application's name is
/// the one thing each passes in.
///
/// Each sentence is read in the person's language, as the bundle negotiates it.
/// A test reads one in another by `language`, so that it does not depend on the
/// machine's.
public nonisolated enum UpdateWords {
    /// The language the words are read in: the one the resource bundle
    /// negotiates for this process, unless a test names another.
    @TaskLocal static var language: Locale?

    private static var locale: Locale {
        language ?? Locale(identifier: Bundle.module.preferredLocalizations.first ?? "en")
    }

    private static var bundle: CompatLocalizedStringResource.BundleDescription { .atURL(Bundle.module.bundleURL) }

    // MARK: The card

    public static var cardTitle: String {
        String(compatLocalized: CompatLocalizedStringResource("Update available", locale: locale, bundle: bundle))
    }

    public static var cardButton: String {
        String(compatLocalized: CompatLocalizedStringResource("Get Update", locale: locale, bundle: bundle))
    }

    /// What VoiceOver says for the card's close button.
    public static var cardClose: String {
        String(compatLocalized: CompatLocalizedStringResource("Later", locale: locale, bundle: bundle))
    }

    /// "Andarium 1.1 (16) is out. You have 1.0 (15)."
    public static func cardLine(app: String, label: String, installed: String) -> String {
        String(compatLocalized: CompatLocalizedStringResource("\(app) \(label) is out. You have \(installed).", locale: locale, bundle: bundle))
    }

    // MARK: The detail

    /// The detail's title: the application and the version, no words.
    public static func detailTitle(app: String, version: String) -> String { "\(app) \(version)" }

    public static func versionLine(_ label: String) -> String {
        String(compatLocalized: CompatLocalizedStringResource("Version \(label)", locale: locale, bundle: bundle))
    }

    public static var released: String {
        String(compatLocalized: CompatLocalizedStringResource("Released", locale: locale, bundle: bundle))
    }

    public static var size: String { String(compatLocalized: CompatLocalizedStringResource("Size", locale: locale, bundle: bundle)) }

    public static var requires: String {
        String(compatLocalized: CompatLocalizedStringResource("Requires", locale: locale, bundle: bundle))
    }

    public static var installed: String {
        String(compatLocalized: CompatLocalizedStringResource("Installed", locale: locale, bundle: bundle))
    }

    public static func requiresValue(_ os: UpdateOSVersion) -> String {
        String(compatLocalized: CompatLocalizedStringResource("iOS \(os.description) or later", locale: locale, bundle: bundle))
    }

    /// The tool's name is a proper name and stays as it is in every language.
    public static func updateWith(_ tool: UpdateTool) -> String {
        String(compatLocalized: CompatLocalizedStringResource("Update with \(tool.name)", locale: locale, bundle: bundle))
    }

    public static var downloadAppFile: String {
        String(compatLocalized: CompatLocalizedStringResource("Download App File", locale: locale, bundle: bundle))
    }

    public static var openReleasePage: String {
        String(compatLocalized: CompatLocalizedStringResource("Open Release Page", locale: locale, bundle: bundle))
    }

    /// What the detail says under its rows: the same Apple ID and the same app
    /// replace this version and keep the virtual machine.
    public static var sameAppleID: String {
        String(compatLocalized: CompatLocalizedStringResource(
                "Install it with the same Apple ID and the same app as before, so it replaces this version and keeps your virtual machine.",
                locale: locale, bundle: bundle))
    }

    public static var stepsTitle: String {
        String(compatLocalized: CompatLocalizedStringResource("How to update", locale: locale, bundle: bundle))
    }

    public static var steps: [String] {
        [
            String(compatLocalized: CompatLocalizedStringResource("Download the app file.", locale: locale, bundle: bundle)),
            String(compatLocalized: CompatLocalizedStringResource(
                    "Install it with the same app or computer and the same Apple ID as before.", locale: locale,
                    bundle: bundle)),
        ]
    }

    public static var skip: String {
        String(compatLocalized: CompatLocalizedStringResource("Skip This Version", locale: locale, bundle: bundle))
    }

    public static var done: String { String(compatLocalized: CompatLocalizedStringResource("Done", locale: locale, bundle: bundle)) }

    // MARK: Info

    public static var infoHeader: String {
        String(compatLocalized: CompatLocalizedStringResource("Updates", locale: locale, bundle: bundle))
    }

    public static var infoRow: String {
        String(compatLocalized: CompatLocalizedStringResource("Update Available", locale: locale, bundle: bundle))
    }

    public static var checkSwitch: String {
        String(compatLocalized: CompatLocalizedStringResource("Check for Updates", locale: locale, bundle: bundle))
    }

    /// What the check reads and sends, under its switch.
    public static var checkFootnote: String {
        String(compatLocalized: CompatLocalizedStringResource(
                "Checks once a day for a newer version. Sends no account, identifier or usage data.", locale: locale,
                bundle: bundle))
    }

    // MARK: Formats

    /// The size as every size in the applications is written: "1.29 GiB".
    public static func sizeText(_ version: UpdateVersion) -> String { Formats.size(bytes: version.sizeBytes) }
}
