// SPDX-License-Identifier: GPL-2.0-or-later

import AndariumCore
import GuestHostCore
import Foundation

/// The kinds of operation the snapshot screens run, for the words that say
/// which one did not go ahead.
enum SnapshotOperation: Equatable {
    case take, restore, delete, rename
}

/// What is known of the snapshot a restore that did not finish names.
enum UnfinishedRestoreKind: Equatable {
    /// A snapshot that is whole: Start finishes the restore.
    case named
    /// The record of the restore cannot be read, so which snapshot is not known.
    case unreadable
    /// The record names a snapshot that is gone or damaged: a start drops the restore.
    case lost
}

/// Every word of the snapshot screens that is said from a value: the driver
/// returns refusals, plans and figures, never text, and each screen says them
/// here (`Andarium/README.md#model-and-storage`). Nothing in this file reads
/// a view or a model.
enum SnapshotWords {
    static let title = String(compatLocalized: "Snapshots")
    static let manage = String(compatLocalized: "Manage")
    static let manageAccessibility = String(compatLocalized: "Manage snapshots")
    static let take = String(compatLocalized: "Take snapshot")
    static let none = String(compatLocalized: "None yet")
    static let spaceLink = String(compatLocalized: "How snapshots use space")
    static let needsNewerApp = String(compatLocalized: "Needs a newer Andarium")
    static let cannotBeRestored = String(compatLocalized: "Can\u{2019}t be restored")
    static let damaged = String(compatLocalized: "Damaged")

    // MARK: Figures and dates

    /// "3 snapshots".
    static func count(_ count: Int) -> String { String(compatLocalized: "\(count) snapshots") }

    /// "1.2 GiB", and "At least 1.2 GiB" where only a lower bound is known.
    static func size(_ figure: SnapshotFigure, capitalized: Bool = true) -> String {
        let text = Formats.size(bytes: figure.bytes)
        guard figure.isLowerBound else { return text }
        return capitalized ? String(compatLocalized: "At least \(text)") : String(compatLocalized: "at least \(text)")
    }

    /// What VoiceOver says of a row's figure.
    static func freesAccessibility(_ figure: SnapshotFigure) -> String {
        let text = Formats.size(bytes: figure.bytes)
        return figure.isLowerBound
            ? String(compatLocalized: "Frees at least \(text) if deleted") : String(compatLocalized: "Frees \(text) if deleted")
    }

    /// "Nov 11, 2026 at 7:45 AM", in the person's own format.
    static func taken(_ date: Date) -> String { date.formatted(date: .abbreviated, time: .shortened) }

    /// The two halves of `taken`: "Nov 11, 2026" and "7:45 AM", for a column
    /// too narrow to hold them on one line.
    static func takenDate(_ date: Date) -> String { date.formatted(date: .abbreviated, time: .omitted) }
    static func takenTime(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }

    /// The date with the month in full, for a snapshot's page.
    static func takenLong(_ date: Date) -> String { date.formatted(date: .long, time: .shortened) }

    /// "r20", or a release ID that is not in the naming scheme as it is.
    static func revision(of releaseID: String) -> String { ReleaseLabel.revision(of: releaseID) }

    /// Home's row: "None yet", "1 snapshot", "5 snapshots \u{00B7} 4.6 GiB".
    /// `total` is nil while the figures are not measured.
    static func homeSubtitle(count: Int, total: SnapshotFigure?) -> String {
        guard count > 0 else { return none }
        guard let total else { return Self.count(count) }
        return String(compatLocalized: "\(Self.count(count)) \u{00B7} \(size(total, capitalized: false))")
    }

    /// The sheet's subtitle: "4.6 GiB on this iPhone", "At least 4.6 GiB on this iPhone".
    static func sheetSubtitle(total: SnapshotFigure, device: String) -> String {
        String(compatLocalized: "\(size(total)) on this \(device)")
    }

    // MARK: Rows and pages

    /// The name, or when it was taken where it has none.
    static func title(of item: SnapshotSummary) -> String {
        item.name.isEmpty ? taken(item.created) : item.name
    }

    /// Under a row's title: "Nov 11, 2026 at 7:45 AM \u{00B7} r20" under a name,
    /// "r20" under a date.
    static func rowDetail(of item: SnapshotSummary) -> String {
        let release = revision(of: item.releaseID)
        return item.name.isEmpty ? release : String(compatLocalized: "\(taken(item.created)) \u{00B7} \(release)")
    }

    /// The orange line under a snapshot that cannot be restored by this app version.
    static func rowFlag(_ restore: SnapshotRestorePlan) -> String? {
        guard case .refused(let reason) = restore else { return nil }
        switch reason {
        case .newerAndroid, .olderDataLayout: return needsNewerApp
        case .incomplete: return damaged
        default: return cannotBeRestored
        }
    }

    /// Beneath Restore: what it does, or why this app version cannot.
    /// `appRevision` is the Android this app carries; `endsUpdate` is set
    /// while the guest has an update that did not finish, which a restore ends.
    static func restoreNote(of item: SnapshotSummary, appRevision: String, endsUpdate: Bool) -> String {
        switch item.restore {
        case .asIs:
            return Sentences.join(
                [String(compatLocalized: "Replaces the virtual machine\u{2019}s current data with this snapshot.")]
                    + endingUpdate(endsUpdate))
        case .updatesAtNextStart(let from, let to):
            return Sentences.join(
                [String(compatLocalized: "Replaces the virtual machine\u{2019}s current data with this snapshot, which is from \(revision(of: from)).")]
                    + [updatesAtNextStart(to: revision(of: to))] + endingUpdate(endsUpdate))
        case .refused(let reason):
            return refusal(reason, snapshot: item, appRevision: appRevision)
        }
    }

    /// "The next start updates it to r20."
    private static func updatesAtNextStart(to revision: String) -> String {
        String(compatLocalized: "The next start updates it to \(revision).")
    }

    /// The sentence that says a restore ends the unfinished update, when it does.
    private static func endingUpdate(_ endsUpdate: Bool) -> [String] {
        endsUpdate ? [String(compatLocalized: "The unfinished system image update ends.")] : []
    }

    private static let cannotBeUndone = String(compatLocalized: "This can\u{2019}t be undone.")

    // MARK: Prompts

    static func restoreTitle(of item: SnapshotSummary) -> String {
        item.name.isEmpty
            ? String(compatLocalized: "Restore this snapshot?") : String(compatLocalized: "Restore \u{201C}\(item.name)\u{201D}?")
    }

    static func restoreMessage(of item: SnapshotSummary, endsUpdate: Bool) -> String {
        var sentences = [
            String(compatLocalized: "The virtual machine\u{2019}s current data is replaced by this snapshot from \(taken(item.created)), and anything not in it is deleted. Some apps may ask you to sign in again.")
        ]
        if case .updatesAtNextStart(_, let to) = item.restore { sentences.append(updatesAtNextStart(to: revision(of: to))) }
        sentences += endingUpdate(endsUpdate)
        sentences.append(cannotBeUndone)
        return Sentences.join(sentences)
    }

    static func deleteTitle(of item: SnapshotSummary) -> String {
        item.name.isEmpty
            ? String(compatLocalized: "Delete the snapshot from \(taken(item.created))?")
            : String(compatLocalized: "Delete \u{201C}\(item.name)\u{201D}?")
    }

    /// What deleting frees, when the figure is measured; otherwise only that
    /// it can't be undone.
    static func deleteMessage(frees: SnapshotFigure?) -> String {
        guard let frees else { return cannotBeUndone }
        let text = Formats.size(bytes: frees.bytes)
        return Sentences.join(
            frees.isLowerBound ? String(compatLocalized: "Deleting it frees at least \(text).") : String(compatLocalized: "Deleting it frees \(text)."),
            cannotBeUndone)
    }

    static let takeAlertMessage = String(compatLocalized: "A new snapshot takes no space. It grows as the virtual machine changes after it.")

    // MARK: Home

    /// The notice after a restore: its title and text.
    static let restoredTitle = String(compatLocalized: "Snapshot restored")

    static func restoredText(_ notice: RestoredSnapshotNotice) -> String {
        var sentences = [
            notice.name.isEmpty
                ? String(compatLocalized: "The virtual machine\u{2019}s data is back to the snapshot from \(taken(notice.created)).")
                : String(compatLocalized: "The virtual machine\u{2019}s data is back to \u{201C}\(notice.name)\u{201D} from \(taken(notice.created)).")
        ]
        if let updatesTo = notice.updatesTo { sentences.append(updatesAtNextStart(to: updatesTo)) }
        return Sentences.join(sentences)
    }

    /// While a restore stands unfinished, from this attempt or an earlier session.
    static let unfinishedTitle = String(compatLocalized: "Snapshot restore not finished")

    /// `item` is the snapshot being restored, for a restore of a snapshot that
    /// is `.named`. Otherwise (the record cannot be read, or the snapshot is
    /// gone or damaged) only what is known is said: the files may hold either
    /// state, and a start drops the restore.
    static func unfinishedText(_ kind: UnfinishedRestoreKind, item: SnapshotSummary?, failure: SnapshotFailure?) -> String {
        var sentences: [String]
        if kind == .named, let item {
            sentences = [
                item.name.isEmpty
                    ? String(compatLocalized: "Andarium could not finish restoring the snapshot from \(taken(item.created)). Starting finishes it.")
                    : String(compatLocalized: "Andarium could not finish restoring \u{201C}\(item.name)\u{201D} from \(taken(item.created)). Starting finishes it.")
            ]
            if case .updatesAtNextStart(_, let to) = item.restore { sentences.append(updatesAtNextStart(to: revision(of: to))) }
        } else {
            sentences = [
                unfinishedReason(kind == .lost ? .lost : .unreadable),
                String(compatLocalized: "The virtual machine\u{2019}s data may be from before the restore or from the snapshot."),
            ]
        }
        if let failure { sentences.append(String(compatLocalized: "The last attempt stopped: \(sentence(failure.description))")) }
        return Sentences.join(sentences)
    }

    /// `text` ended by one full stop: some descriptions of the system's errors
    /// carry theirs.
    private static func sentence(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last, !".!?".contains(last) else { return trimmed }
        return trimmed + "."
    }

    /// Erase guest's alert says what goes with the guest.
    static func eraseMessage(snapshots: Int) -> String {
        switch snapshots {
        case 0:
            String(compatLocalized: "Everything the virtual machine has stored is deleted. This can\u{2019}t be undone.")
        case 1:
            String(compatLocalized: "Everything the virtual machine has stored is deleted, and its snapshot with it. This can\u{2019}t be undone.")
        default:
            String(compatLocalized: "Everything the virtual machine has stored is deleted, and its \(snapshots) snapshots with it. This can\u{2019}t be undone.")
        }
    }

    /// Low space says snapshots are a way out, when there are some.
    static func lowSpaceText(hasSnapshots: Bool, startReserve: String, device: String) -> String {
        hasSnapshots
            ? String(compatLocalized: "The virtual machine needs \(startReserve) free to start. Free up space in Settings \u{203A} General \u{203A} \(device) Storage, or delete snapshots.")
            : String(compatLocalized: "The virtual machine needs \(startReserve) free to start. Free up space in Settings \u{203A} General \u{203A} \(device) Storage.")
    }

    /// The card for an app too old for the guest's data says an older snapshot
    /// is a way back, when there is one.
    static func blockedText(_ reason: StartBlock, hasOlderSnapshot: Bool) -> String {
        guard reason == .olderAndroid, hasOlderSnapshot else { return reason.explanation }
        return String(compatLocalized: "This app version is older than the one the virtual machine last started with, and its data does not go back. Install a newer version of Andarium, restore an older snapshot, or erase the virtual machine to start again with this one.")
    }

    /// Backup's note says snapshots are not in a backup, when there are some.
    static func backupNote(device: String, hasSnapshots: Bool) -> String {
        Sentences.join(
            [String(compatLocalized: "Puts the virtual machine’s apps and files in iCloud and computer backups of this \(device).")]
                + (hasSnapshots ? [String(compatLocalized: "Snapshots are not included.")] : []))
    }

    // MARK: What is unavailable

    /// Above the dimmed Take snapshot; nil when nothing needs saying (it is
    /// available, or an operation is under way and shows itself).
    /// `restore` says what is known of the snapshot of a restore that did not
    /// finish (`unfinishedReason`).
    static func takeReason(_ refusal: SnapshotRefusal, restore: UnfinishedRestoreKind = .named) -> String? {
        switch refusal {
        case .busy: nil
        case .guestNotStopped: String(compatLocalized: "Not while the virtual machine is starting or running.")
        case .noData: String(compatLocalized: "Start the virtual machine once first. Until then there is no data to keep.")
        case .unreadableRecord: String(compatLocalized: "The virtual machine\u{2019}s records cannot be read, so its data cannot be snapshotted.")
        case .notShutDown:
            String(compatLocalized: "Android wasn\u{2019}t shut down when the virtual machine last ran. Start the virtual machine and shut it down from Android, then take a snapshot.")
        case .unfinishedUpdate:
            String(compatLocalized: "Not while the system image update is unfinished. Update and start tries it again, or use Restore on Home.")
        case .mismatch: String(compatLocalized: "Not while the virtual machine\u{2019}s files do not match this app version.")
        case .volumeCannotClone: String(compatLocalized: "The virtual machine\u{2019}s data cannot be snapshotted (it needs an APFS volume).")
        case .restoreUnfinished: unfinishedReason(restore)
        default: nil
        }
    }

    /// Why nothing new is done while a restore stands unfinished. Start
    /// finishes it only where the snapshot is whole: a restore whose record
    /// cannot be read, or whose snapshot is gone or damaged, is dropped at the
    /// next start, which finishes nothing.
    static func unfinishedReason(_ kind: UnfinishedRestoreKind) -> String {
        switch kind {
        case .named: String(compatLocalized: "A restore did not finish. Starting finishes it.")
        case .unreadable: String(compatLocalized: "A snapshot restore did not finish, and Andarium cannot read which one.")
        case .lost: String(compatLocalized: "A snapshot restore did not finish, and its snapshot is missing or damaged.")
        }
    }

    /// Why a snapshot cannot be restored or deleted for now, shown in place of
    /// what Restore does; nil for a refusal that is about the snapshot itself.
    static func nowReason(_ refusal: SnapshotRefusal, restore: UnfinishedRestoreKind = .named) -> String? {
        switch refusal {
        case .guestNotStopped: String(compatLocalized: "Not while the virtual machine is starting or running.")
        case .busy: String(compatLocalized: "Another snapshot operation is under way.")
        case .restoreUnfinished: unfinishedReason(restore)
        default: nil
        }
    }

    // MARK: Refusals and failures

    /// The title of the alert for an operation that did not go ahead.
    static func problemTitle(_ operation: SnapshotOperation) -> String {
        switch operation {
        case .take: String(compatLocalized: "The snapshot could not be taken")
        case .restore: String(compatLocalized: "The snapshot could not be restored")
        case .delete: String(compatLocalized: "The snapshot could not be deleted")
        case .rename: String(compatLocalized: "The snapshot could not be renamed")
        }
    }

    /// Every refusal in words. `snapshot` is the one the refusal is about, if
    /// any; `appRevision` the Android this app carries.
    static func refusal(
        _ refusal: SnapshotRefusal, snapshot: SnapshotSummary? = nil, appRevision: String = "", device: String = "device",
        restore: UnfinishedRestoreKind = .named
    ) -> String {
        switch refusal {
        case .guestNotStopped:
            return String(compatLocalized: "The virtual machine is starting or running. Snapshots can be taken, restored and deleted only while it is stopped.")
        case .busy:
            return String(compatLocalized: "Another snapshot operation is under way. Try again in a moment.")
        case .noData, .unreadableRecord, .notShutDown, .unfinishedUpdate, .mismatch, .volumeCannotClone:
            return takeReason(refusal, restore: restore) ?? ""
        case .notEnoughSpace:
            return String(compatLocalized: "There is not enough free space on this \(device). Free up space in Settings \u{203A} General \u{203A} \(device) Storage and try again.")
        case .newerAndroid:
            if let snapshot {
                return String(compatLocalized: "This snapshot is from \(revision(of: snapshot.releaseID)), newer than this app\u{2019}s \(appRevision). Update Andarium to restore it.")
            }
            return String(compatLocalized: "This snapshot is from a newer release, newer than this app\u{2019}s \(appRevision). Update Andarium to restore it.")
        case .olderDataLayout:
            return String(compatLocalized: "This snapshot\u{2019}s data uses a newer layout than this app version can open. Update Andarium to restore it.")
        case .differentSystem:
            return String(compatLocalized: "This snapshot was taken with a different system image of the same release, so this app version can\u{2019}t restore it.")
        case .diskSizeNotAccepted(let gib):
            return String(compatLocalized: "This snapshot\u{2019}s disk is \(gib) GiB, a size this app version does not accept. It can only be deleted.")
        case .incomplete:
            return String(compatLocalized: "Some of this snapshot\u{2019}s files are missing, so it can\u{2019}t be restored. It can only be deleted.")
        case .missing:
            return String(compatLocalized: "This snapshot is not there any more.")
        case .restoreUnfinished:
            return unfinishedReason(restore)
        case .invalidName:
            return String(compatLocalized: "A name has at most \(SnapshotRules.maximumNameLength) characters, and no line breaks, tabs or other control characters.")
        }
    }

    // MARK: The space page

    static let spacePageTitle = String(compatLocalized: "Snapshot space")

    /// The explanation, one short paragraph each. The ones about the lower bound
    /// and the unfinished update apply only when they do.
    static func spaceParagraphs(device: String, lowerBound: Bool, hasUpdateCopy: Bool) -> [String] {
        var paragraphs = [
            String(compatLocalized: "A new snapshot takes no space. When Android later changes or deletes data, the snapshot keeps the old version, so it grows as the virtual machine is used, and by a lot after an update of Android."),
            String(compatLocalized: "The size beside a snapshot is what deleting it frees. Snapshots can share old data that none of them frees alone, so together they use more than their sizes add up to."),
        ]
        if lowerBound {
            paragraphs.append(String(compatLocalized: "This \(device) measures only part of what snapshots share, so they use at least the size shown."))
        }
        if hasUpdateCopy {
            paragraphs.append(String(compatLocalized: "The unfinished system image update keeps its own copy until it ends. Restoring a snapshot ends it."))
        }
        paragraphs += [
            String(compatLocalized: "Deleting files in Android frees nothing a snapshot still keeps. Deleting or restoring a snapshot gives space back."),
            String(compatLocalized: "Snapshots stay on this \(device). They are not in backups, and Erase virtual machine deletes them."),
        ]
        return paragraphs
    }
}
