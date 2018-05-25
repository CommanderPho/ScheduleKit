/*
 *  SCKEventHolder.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 24/12/2014.
 *  Copyright:  © 2014-2017 Guillem Servera (http://github.com/gservera)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

import Cocoa

/// Instances of this class work in conjunction with an `SCKEventView` and 
/// represent an object conforming to the `SCKEvent` protocol. These objects are
/// automatically created by the `SCKViewController` reloadData methods.
internal final class SCKEventHolder: NSObject {

    // For any event of duration less than the set minimum, it will draw as if it were the minimum duration instead.
    // This prevents not being able to read the text or see the event view because the duration is too small.
    internal var minimumEventDisplayDuration: Int {
        return 30
    }

    /// Initializes a new instance representing a given event object associated
    /// with a concrete `SCKEventView`, managed by the same controller. Returns
    /// `nil` when the represented object's scheduled date or duration cannot
    /// be represented in the controller's schedule view date bounds.
    /// - Parameters:
    ///   - event: The represented object.
    ///   - view: The event view for this instance. Must have been added to a 
    ///           view hierarchy at this point.
    ///   - controller: The `SCKViewController` instance managing this holder.
    ///
    init?(event: SCKEvent, view: SCKEventView, controller: SCKViewController) {
        representedObject = event
        cachedDuration = event.duration
        cachedScheduledDate = event.scheduledDate
        cachedTitle = event.title
        cachedUser = event.user
        eventView = view
        self.controller = controller

        super.init()

        recalculateRelativeValues()

        guard isReady else {
            return nil
        }

        let obj = representedObject as AnyObject & SCKEvent
        addDurationObserver(on: obj)
        addScheduledDateObserver(on: obj)
        addTitleObserver(on: obj)
        addUserEventColorObserver(on: obj)
        addUserReducedEmphasisEventColorObserver(on: obj)
        addUserEventOverlayColorObserver(on: obj)
        addUserReducedEmphasisEventOverlayColorObserver(on: obj)
    }

    // MARK: - Object state

    /// The event object backed by this event holder. Cannot be changed.
    let representedObject: SCKEvent

    /// A reference to the `SCKEventView` associated with this event holder.
    private(set) weak var eventView: SCKEventView?

    /// A convenience reference to the controller that created this holder.
    private weak var controller: SCKViewController?

    // MARK: Cached properties

    // These properties ensure the integrity of the layout process by keeping
    // their values until the layout process has ended, even if a change from 
    // represented object is observed.

    /// A local copy of the represented object's duration. It is automatically
    /// uppdated when observed changes from the represented object are processed.
    internal var cachedDuration: Int

    /// A local copy of the represented object's date. It is automatically
    /// uppdated when observed changes from the represented object are processed.
    internal var cachedScheduledDate: Date

    /// A local copy of the represented object's title. It is automatically
    /// uppdated when observed changes from the represented object are processed.
    internal var cachedTitle: String

    /// A local copy of the represented object's user. It is automatically
    /// uppdated when observed changes from the represented object are processed.
    /// - Note: We observe the user instead of her color directly to make sure
    ///         the user changes trigger a notification.
    internal weak var cachedUser: SCKUser?

    // MARK: Relative properties

    /// The relative start time of the event in the `scheduleView` date bounds.
    internal var relativeStart = SCKRelativeTimeLocationInvalid

    /// The relative end time of the event in the `scheduleView` date bounds.
    internal var relativeEnd = SCKRelativeTimeLocationInvalid

    /// The relative duration of the event in the `scheduleView` date bounds.
    internal var relativeLength = SCKRelativeTimeLengthInvalid

    internal var timeSubindicatorConfig: TickSubinidcatorConfig? = nil

    /// Indicates whether relative values are valid or not, thus if layout is safe.
    private(set) var isReady: Bool = false

    /// Invalidates the holder's cached properties and recalculates them by
    /// comparing the values from the represented object's `duration` and
    /// `scheduledDate` properties and the schedule view date bounds.
    /// This method might be invoked automatically:
    /// - When the `SCKEventHolder` object is initialized.
    /// - Whenever `scheduledDate` and/or `duration` change if unlocked.
    /// - When the schedule view ends a dragging operation.
    /// - On already existing event holders during a reload data phase (such as
    ///   changing the day count in a week view).
    ///
    /// - Note: This method is not called automatically when the schedule view
    ///         date bounds change, since the respective reloadData method is
    ///         called instead.
    internal func recalculateRelativeValues() {
        // If view is not set, then do nothing.
        guard let rootView = eventView?.scheduleView else { return }
        let convertedRelativeMinimumHeight: SCKRelativeTimeLength = SCKRelativeTimeLength(self.minimumEventDisplayDuration)
        var needsApplyTimeSubindicator: Bool = false

        // Invalidate state.
        isReady = false
        relativeStart = SCKRelativeTimeLocationInvalid
        relativeEnd = SCKRelativeTimeLocationInvalid
        relativeLength = 0
        // Calculate new start
        relativeStart = rootView.calculateRelativeTimeLocation(for: cachedScheduledDate)
        if relativeStart != SCKRelativeTimeLocationInvalid {
//            let minimumHeight: CGFloat = self.minimumEventHeight
//            let convertedRelativeMinimumHeight: SCKRelativeTimeLength = rootView.calculateRelativeTimeDuration(for: minimumHeight)

            if cachedDuration > 0 {
                let inSeconds = SCKRelativeTimeLength(cachedDuration * 60)
                let endDate = cachedScheduledDate.addingTimeInterval(inSeconds)
                relativeEnd = rootView.calculateRelativeTimeLocation(for: endDate)
                }
            else { // For instantaneous events
                self.cachedDuration = Int(convertedRelativeMinimumHeight)
                let inSeconds = SCKRelativeTimeLength(cachedDuration * 60)
                let endDate = cachedScheduledDate.addingTimeInterval(inSeconds)
                relativeEnd = rootView.calculateRelativeTimeLocation(for: endDate)

                if let validTimeSubindicator = self.timeSubindicatorConfig {
                    self.timeSubindicatorConfig!.eventViewRelativeOffset = 0.0
                }
                else {
//                    self.timeSubindicatorConfig = TickSubinidcatorConfig(thickness: 1.0, color: NSColor.red, height: 1.0, eventViewRelativeOffset: 0.0)
                    self.timeSubindicatorConfig = TickSubinidcatorConfig(eventViewRelativeOffset: 0.0)
                }
                needsApplyTimeSubindicator = true


//                let eventStartOffset: CGFloat = rootView.contentRect.height * CGFloat(relativeStart)
//                // TODO: make sure it doesn't exceed the rootView's bounds
//                let proposedRelativeEnd = relativeStart + convertedRelativeMinimumHeight
//                let proposedEndOffset: CGFloat = eventStartOffset + minimumHeight
//
//                if (rootView.contentRect.height >= proposedEndOffset) {
//                    relativeEnd = SCKRelativeTimeLocation(proposedRelativeEnd)
//                }
//                else {
//                    // Spans out of the displayed day area!
//                    relativeEnd = SCKRelativeTimeLocationInvalid
//                }
            }

            if relativeEnd == SCKRelativeTimeLocationInvalid {
                relativeEnd = 1.0 // Truncate event to the end of the view (note this might violate the minimum size, but we'll ignore that for now.
            }
            var proposedRelativeLength = relativeEnd - relativeStart
//            if (proposedRelativeLength < convertedRelativeMinimumHeight) {
//                // Must adjust relative end or relative start to match the required relative length
//                var remainingLengthToFill = convertedRelativeMinimumHeight - proposedRelativeLength
//                // Begin by shifting the end down as much as possible.
//                let availableBelowOffset = 1.0 - relativeEnd
//                // If there is any space below the current relativeEnd, fill it
//                if (availableBelowOffset > 0.0) {
//                    // Move down by the available below offset
//                    relativeEnd = relativeEnd + remainingLengthToFill
//                    // Clamp to the maximum (1.0)
//                    relativeEnd = max(relativeEnd, 1.0)
//
//                    //Compute the updated difference
//                    proposedRelativeLength = relativeEnd - relativeStart
//                    remainingLengthToFill = convertedRelativeMinimumHeight - proposedRelativeLength
//                }
//
//                // If that update was still enough try to shift the event's relativeStart up to compensate
//                if (remainingLengthToFill > 0.0) {
//                    relativeStart = (relativeStart - remainingLengthToFill)
//                    relativeStart = min(0.0, relativeStart) // Ensure the adjustment doesn't escape the box
//                    //Compute the updated difference
//                    proposedRelativeLength = relativeEnd - relativeStart
//                    remainingLengthToFill = convertedRelativeMinimumHeight - proposedRelativeLength
//                }
//
//                if (remainingLengthToFill > 0.0) {
//                    print("Error! The view is too smmall to satisify the minimum EventView height requirements!")
//                }
//                // Otherwise it has been resolved to the best of our ability.
//            }

            relativeLength = proposedRelativeLength
            if (needsApplyTimeSubindicator) {
                self.eventView?.timeSubindicatorConfig = self.timeSubindicatorConfig
                self.eventView?.needsDisplay = true
            }
            isReady = true
        }
    }

    // MARK: - Conflict tracking

    /// The number of events in conflict with this. Includes self, so min is 1.
    internal var conflictCount: Int = 1

    /// The position of this event among the events in conflict (zero based).
    internal var conflictIndex: Int = 0

    /// When observing represented object changes, the events in conflict whith
    /// this one before the actual change takes place.
    private var previousConflicts: Set<SCKEventHolder> = []

    // MARK: - Change observing

    /// Set to `true` when observed changes observed from `representedObject`
    /// should be ignored (either when the schedule view itself is making the
    /// change or when the represented object is not valid anymore).
    private var shouldIgnoreChanges: Bool = false

    private var changeObserations = [NSKeyValueObservation]()

    // MARK: - State freezing

    /// Indicates whether the event holder is frozen or not. When an instance is
    /// frozen, it works as a snapshot of the instance's state when it was frozen,
    /// so its cached values don't get updated when the corresponding properties
    /// in the represented object change.
    ///
    /// Nevertheless, changes in represented object are still observed in frozen
    /// objects, with the difference that they're not parsed until the
    /// `unfreeze()` method is called.
    ///
    /// This is particularly useful and so invoked automatically during layout,
    /// where cached values should remain the same during the whole process.
    private(set) var isFrozen: Bool = false

    /// The changes observed while the object was frozen.
    private var changesWhileFrozen: [DelayedChange] = []

    /// Snapshots the holder's relative properties and begins caching subsequent
    /// changes observed from the represented object until `unfreeze()` is called.
    /// Called by the schedule view during relayout and dragging operations to
    /// preserve data integrity.
    internal func freeze() {
        guard !isFrozen else {
            print("Warning: Called freeze() on an already frozen holder.")
            return
        }
        isFrozen = true
    }

    /// Stops caching changes observed from the represented object and processes
    /// any pending changes cached while the object was frozen. Called by the 
    /// schedule view during relayout and dragging operations to preserve data 
    /// integrity.
    internal func unfreeze() {
        guard isFrozen else {
            print("Warning: Called unfreeze() on an already unfrozen holder.")
            return
        }
        isFrozen = false

        // Process pending changes
        for c in changesWhileFrozen {
            c.commit()
        }
        changesWhileFrozen = []
    }
}

// MARK: - Change observation
internal extension SCKEventHolder {
    /// A wrapper around a deferred change from the `representedObject`.
    private struct DelayedChange {
        /// The changed key path.
        let closure: ((Any) -> Void)
        /// The observed change dictionary.
        let parameter: Any

        init<T>(function: @escaping ((T) -> Void), parameter: T) {
            self.closure = { (any) in
                guard let casted = any as? T else {
                    fatalError("Could not type-safe call delayed change closure")
                }
                function(casted)
            }
            self.parameter = parameter
        }

        func commit() {
            closure(parameter)
        }
    }

    /// Begins ignoring changes observed from `representedObject`. This method is
    /// called by the event view when commiting a dragging operation to avoid
    /// observing its own changes. It's also called before deallocation when the
    /// controller discards it during a reload data phase.
    internal func stopObservingRepresentedObjectChanges() {
        shouldIgnoreChanges = true
    }

    /// Stops ignoring changes observed from `representedObject`. This method is
    /// called by the event view after commiting a dragging operation.
    internal func resumeObservingRepresentedObjectChanges() {
        shouldIgnoreChanges = false
    }

    private func processOrEnqueueChange<T>(closure: @escaping (T) -> Void, parameter: T) {
        guard !self.isFrozen else {
            let cachedChange = DelayedChange(function: closure, parameter: parameter)
            self.changesWhileFrozen.append(cachedChange)
            return
        }
        closure(parameter)
    }

    private func addDurationObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, Int> = \T.duration
        let observation = object.observe(keyPath, options: [.prior, .old, .new]) { [unowned self] (_, change) in
            guard !self.shouldIgnoreChanges else { return }
            guard !change.isPrior else {
                self.previousConflicts = Set(self.controller!.resolvedConflicts(for: self))
                return
            }

            let closure: ((Int) -> Void) = { [weak self] (newDuration) in
                guard let strongSelf = self else { return }

                strongSelf.cachedDuration = newDuration
                strongSelf.recalculateRelativeValues()

                let conflictsNow = Set(strongSelf.controller!.resolvedConflicts(for: strongSelf))
                let updatingHolders = strongSelf.previousConflicts.union(conflictsNow)
                let updatingViews = updatingHolders.flatMap { $0.eventView }
                strongSelf.eventView?.scheduleView?.invalidateLayout(for: updatingViews)
            }

            guard let changed = change.newValue else { fatalError("Could not get new value") }
            guard changed != self.cachedDuration else { return }
            self.processOrEnqueueChange(closure: closure, parameter: changed)
        }
        changeObserations.append(observation)
    }

    private func addScheduledDateObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, Date> = \T.scheduledDate
        let observation = object.observe(keyPath, options: [.prior, .old, .new]) { [unowned self] (_, change) in
            guard !self.shouldIgnoreChanges else { return }
            guard !change.isPrior else {
                self.previousConflicts = Set(self.controller!.resolvedConflicts(for: self))
                return
            }

            let closure: ((Date) -> Void) = { [weak self] (newDate) in
                guard let strongSelf = self, let rootView = strongSelf.eventView?.scheduleView else { return }
                strongSelf.cachedScheduledDate = newDate
                strongSelf.recalculateRelativeValues()

                guard rootView.dateInterval.contains(newDate) else {
                    // Holder is now invalid, reload data will get rid of it.
                    strongSelf.controller?.internalReloadData()
                    return
                }
                let conflictsNow = Set(strongSelf.controller!.resolvedConflicts(for: strongSelf))
                let updatingHolders = strongSelf.previousConflicts.union(conflictsNow)
                let updatingViews = updatingHolders.flatMap { $0.eventView }
                strongSelf.eventView?.scheduleView?.invalidateLayout(for: updatingViews)
            }

            guard let changed = change.newValue else { fatalError("Could not get new value") }
            guard changed != self.cachedScheduledDate else { return }
            self.processOrEnqueueChange(closure: closure, parameter: changed)
        }
        changeObserations.append(observation)
    }

    private func addTitleObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, String> = \T.title
        let observation = object.observe(keyPath, options: [.old, .new]) { [unowned self] (_, change) in
            guard !self.shouldIgnoreChanges && change.oldValue != change.newValue else { return }

            let closure: ((String) -> Void) = { [weak self] (newTitle) in
                guard newTitle != self?.cachedTitle else { return }
                self?.cachedTitle = newTitle
                self?.eventView?.innerLabel.stringValue = newTitle
            }

            guard let changed = change.newValue else { fatalError("Could not get new value") }
            self.processOrEnqueueChange(closure: closure, parameter: changed)
        }
        changeObserations.append(observation)
    }

    private func addUserEventColorObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, NSColor> = \T.user.eventColor
        let observation = object.observe(keyPath, options: [.old, .new]) { [unowned self] (event, change) in
            guard !self.shouldIgnoreChanges else { return }

            let closure: ((SCKUser) -> Void) = { [weak self] (updatedUser) in
                guard let strongSelf = self else { return }
                if strongSelf.cachedUser !== updatedUser {
                    strongSelf.cachedUser = updatedUser
                }
                if strongSelf.eventView?.scheduleView?.colorMode == .byEventOwner
                    && change.oldValue != change.newValue {
                    strongSelf.eventView?.backgroundColor = updatedUser.eventColor
                    strongSelf.eventView?.reducedEmphasisBackgroundColor = updatedUser.reducedEmphasisEventColor
                    strongSelf.eventView?.needsDisplay = true
                }
            }
            self.processOrEnqueueChange(closure: closure, parameter: event.user)
        }
        changeObserations.append(observation)
    }

    private func addUserReducedEmphasisEventColorObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, NSColor> = \T.user.reducedEmphasisEventColor
        let observation = object.observe(keyPath, options: [.old, .new]) { [unowned self] (event, change) in
            guard !self.shouldIgnoreChanges else { return }

            let closure: ((SCKUser) -> Void) = { [weak self] (updatedUser) in
                guard let strongSelf = self else { return }
                if strongSelf.cachedUser !== updatedUser {
                    strongSelf.cachedUser = updatedUser
                }
                if strongSelf.eventView?.scheduleView?.colorMode == .byEventOwner
                    && change.oldValue != change.newValue {
                    strongSelf.eventView?.backgroundColor = updatedUser.eventColor
                    strongSelf.eventView?.reducedEmphasisBackgroundColor = updatedUser.reducedEmphasisEventColor
                    strongSelf.eventView?.needsDisplay = true
                }
            }
            self.processOrEnqueueChange(closure: closure, parameter: event.user)
        }
        changeObserations.append(observation)
    }

    private func addUserEventOverlayColorObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, NSColor> = \T.user.eventOverlayColor
        let observation = object.observe(keyPath, options: [.old, .new]) { [unowned self] (event, change) in
            guard !self.shouldIgnoreChanges else { return }

            let closure: ((SCKUser) -> Void) = { [weak self] (updatedUser) in
                guard let strongSelf = self else { return }
                if strongSelf.cachedUser !== updatedUser {
                    strongSelf.cachedUser = updatedUser
                }
                if strongSelf.eventView?.scheduleView?.colorMode == .byEventOwner
                    && change.oldValue != change.newValue {
                    strongSelf.eventView?.overlayColor = updatedUser.eventOverlayColor
                    strongSelf.eventView?.needsDisplay = true
                }
            }
            self.processOrEnqueueChange(closure: closure, parameter: event.user)
        }
        changeObserations.append(observation)
    }

    private func addUserReducedEmphasisEventOverlayColorObserver<T: SCKEvent>(on object: T) {
        let keyPath: KeyPath<T, NSColor> = \T.user.reducedEmphasisEventOverlayColor
        let observation = object.observe(keyPath, options: [.old, .new]) { [unowned self] (event, change) in
            guard !self.shouldIgnoreChanges else { return }

            let closure: ((SCKUser) -> Void) = { [weak self] (updatedUser) in
                guard let strongSelf = self else { return }
                if strongSelf.cachedUser !== updatedUser {
                    strongSelf.cachedUser = updatedUser
                }
                if strongSelf.eventView?.scheduleView?.colorMode == .byEventOwner
                    && change.oldValue != change.newValue {
                    strongSelf.eventView?.reducedEmphasisOverlayColor = updatedUser.reducedEmphasisEventOverlayColor
                    strongSelf.eventView?.needsDisplay = true
                }
            }
            self.processOrEnqueueChange(closure: closure, parameter: event.user)
        }
        changeObserations.append(observation)
    }
}
