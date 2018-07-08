/*
 *  SCKView.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 24/12/2014.
 *  Copyright:  © 2014-2017 Guillem Servera (https://github.com/gservera)
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


/// An abstract NSView subclass that implements the basic functionality to manage
/// a set of event views provided by an `SCKViewController` object. This class
/// provides basic handling of the displayed date interval and methods to convert
/// between these date values and view coordinates.
///
/// In addition, `SCKView` provides the default (and required) implementation for
/// event coloring, selection and deselection, handling double clicks on empty
/// dates and drag & drop.
///
/// - Note: Do not instantiate this class directly.
///
@objc open class SCKView: NSView {

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }


    // Shared amongst all events in the case that the colors cannot be retrieved from the delegate
    @objc public var defaultEventBackgroundColor: NSColor = NSColor.darkGray {
        didSet {
            self.setUp()
        }
    }

    @objc public var defaultEventReducedEmphasisBackgroundColor: NSColor = NSColor(white: 0.85, alpha: 1.0) {
        didSet {
            self.setUp()
        }
    }

    // Shared amongst all events in the case that the colors cannot be retrieved from the delegate
    @objc public var defaultEventOverlayColor: NSColor = NSColor.white {
        didSet {
            self.setUp()
        }
    }

    @objc public var defaultEventReducedEmphasisOverlayColor: NSColor = NSColor.darkGray {
        didSet {
            self.setUp()
        }
    }

    /// This method is intended to provide a common initialization point for all 
    /// instances, regardless of whether they have been initialized using
    /// `init(frame:)` or `init(coder:)`. Default implementation does nothing.
    func setUp() { }

    /// The controller managing this view.
    @IBOutlet public weak var controller: SCKViewController!

    /// The schedule view's delegate.
    @objc public weak var delegate: SCKViewDelegate?
    public weak var colorManagingDelegate: SCKColorManaging? {
        didSet {
            self.setUp()
        }
    }

    public weak var labelManagingDelegate: SCKLabelManaging? {
        didSet {
            self.setUp()
        }
    }

    public weak var layoutManagingDelegate: SCKLayoutManaging? {
        didSet {
            self.setUp()
        }
    }

    // MARK: - NSView overrides

    override open var isFlipped: Bool {
        return true
    }

    override open var isOpaque: Bool {
        return true
    }

    open override func draw(_ dirtyRect: NSRect) {
        if let validColorDelegate = self.colorManagingDelegate {
            validColorDelegate.backgroundColor.setFill()
        }
        else {
            NSColor.white.setFill()
        }
        dirtyRect.fill()
    }

    // MARK: - Date handling

    /// The displayed date interval. Setting this value marks the view as needing
    /// display. You should call a reload data method on the controller object to
    /// provide matching events after calling this method.
    @objc public var dateInterval: DateInterval = DateInterval() {
        didSet { needsDisplay = true }
    }

    // MARK: - Date transforms

    /// Calculates a date by transforming a relative time point in the schedule
    /// view's date interval.
    ///
    /// - Parameter relativeTimeLocation: A valid relative time location.
    /// - Note: Seconds are rounded to the next minute.
    /// - Returns: The calculated date or `nil` if `relativeTimeLocation` is not
    ///            a value compressed between 0.0 and 1.0.
    public final func calculateDate(for relativeTimeLocation: SCKRelativeTimeLocation) -> Date? {
        guard relativeTimeLocation >= 0.0 && relativeTimeLocation <= 1.0 else { return nil; }
        let start = dateInterval.start.timeIntervalSinceReferenceDate
        let length = dateInterval.duration * relativeTimeLocation
        var numberOfSeconds = Int(trunc(start + length))
        // Round to next minute
        while numberOfSeconds % 60 > 0 {
            numberOfSeconds += 1
        }
        return Date(timeIntervalSinceReferenceDate: TimeInterval(numberOfSeconds))
    }

    /// Calculates the relative time location for a given date.
    ///
    /// - Parameter date: A date contained in the schedule view's date interval.
    /// - Returns: A value between 0.0 and 1.0 representing the relative position
    ///            of `date` in the schedule view's date interval; or 
    ///            `SCKRelativeTimeLocationInvalid` if `date` is not contained in
    ///            that interval.
    public final func calculateRelativeTimeLocation(for date: Date) -> SCKRelativeTimeLocation {
        guard dateInterval.contains(date) else { return SCKRelativeTimeLocationInvalid; }
        let dateRef = date.timeIntervalSinceReferenceDate
        let startDateRef = dateInterval.start.timeIntervalSinceReferenceDate
        return (dateRef - startDateRef) / dateInterval.duration
    }


    /// Calculates the relative time location in the view's date interval for a
    /// given point in the view's coordinate system. The default implementation
    /// returns `SCKRelativeTimeLocationInvalid`. Subclasses must override this
    /// method in order to be able to transform screen points into date values.
    ///
    /// - Parameter point: The point for which to perform the calculation.
    /// - Returns: A value between 0.0 and 1.0 representing the relative time
    ///            location for the given point, or `SCKRelativeTimeLocationInvalid`
    ///            in case `point` falls out of the view's content rect.
    public func relativeTimeLocation(for point: CGPoint) -> SCKRelativeTimeLocation {
        return SCKRelativeTimeLocationInvalid
    }

    /// Calculates the relative time length in the view's date interval for a
    /// given height in the view's coordinate system. The default implementation
    /// returns `SCKRelativeTimeLengthInvalid`. Subclasses must override this
    /// method in order to be able to transform screen heights into date lengths.
    ///
    /// - Parameter height: The height for which to perform the calculation.
    /// - Returns: A value between 0.0 and 1.0 representing the relative time
    ///            length for the given point, or `SCKRelativeTimeLengthInvalid`
    ///            in case `height` falls out of the view's content rect.
    public func relativeTimeLength(for height: CGFloat) -> SCKRelativeTimeLength {
        return SCKRelativeTimeLengthInvalid
    }

    //    public final func calculateRelativeTimeDuration(for height: CGFloat) -> SCKRelativeTimeLength {
    //        let size = self.contentRect.size
    //        let totalHight: CGFloat = size.height
    //        if (totalHight <= 0.0) {
    //            return SCKRelativeTimeLengthInvalid
    //        }
    //        else {
    //            let percentHeight = height / totalHight
    //            return SCKRelativeTimeLength(percentHeight)
    //        }
    //    }



    // MARK: - Subview management

    /// An array containing all the event views displayed in this view.
    open var eventViews: [SCKEventView] = []

    /// Registers a recently created `SCKEventView` with this instance. This
    /// method is called from the controller after adding the view as a subview
    /// of this schedule view. You should not call this method directly.
    ///
    /// - Parameter eventView: The event view to be added.
    open func addEventView(_ eventView: SCKEventView) {
        eventViews.append(eventView)
    }

    /// Removes an `SCKEventView` from the array of subviews managed by this
    /// instance. This method is called from the controller before removing the
    /// view from its superview. You should not call this method directly.
    ///
    /// - Parameter eventView: The event view to be removed. Must have been added
    ///                        previously via `addEventView(_:)`.
    open func removeEventView(_ eventView: SCKEventView) {
        guard let index = eventViews.index(of: eventView) else {
            Swift.print("Warning: Attempting to remove an unregistered event view")
            return
        }
        eventViews.remove(at: index)
    }

    // MARK: - Event view layout

    /// The portion of the view used to display events. Defaults to the full view
    /// frame. Subclasses override this property if they display additional items
    /// such as day or hour labels alongside the event views.
    open var contentRect: CGRect {
        return CGRect(origin: .zero, size: frame.size)
    }

    /// Indicates whether an event layout invalidation has been triggered by
    /// invoking the `invalidateFrames(for:)` method. Turns back to `false` when
    /// the invalidation process completes.
    private(set) var isInvalidatingLayout: Bool = false

    /// Override this method to perform additional tasks before the layout
    /// invalidation takes place. If you do so, don't forget to call super.
    open func beginLayoutInvalidation() {
        isInvalidatingLayout = true
    }

    /// Override this method to perform additional tasks after the layout
    /// invalidation has finished. If you do so, don't forget to call super.
    open func endLayoutInvalidation() {
        isInvalidatingLayout = false
    }

    /// Subclasses may override this method to perform additional calculations
    /// required to compute the event view's frame when the `layout()` method is 
    /// called. An example of these calculations include conflict management. The
    /// default implementation does nothing.
    ///
    /// - Parameter eventView: The event view whose frame will be updated soon.
    /// - Note: Since the event view's frame will be eventually calculated in the
    ///         `layout()` method, you must avoid changing its frame in this one.
    open func invalidateLayout(for eventView: SCKEventView) { }

    /// Triggers a series of operations that determine the frame of an array of
    /// `SCKEventView`s according to their event holder's properties and to other
    /// events which could be potentially in conflict with them. Eventually, the
    /// schedule view is marked as needing layout in order to perform the actual
    /// subview positioning and sizing.
    ///
    /// These opertations include freezing all subviews' event holder to guarantee
    /// that their data remains consistent during the whole process even if their
    /// represented object properties change.
    ///
    /// - Parameters:
    ///   - eventViews: The array of event views to be laid out.
    ///   - animated: Pass true to perform an animated subview layout.
    ///
    open func invalidateLayout(for eventViews: [SCKEventView], animated: Bool = false) {
        guard !isInvalidatingLayout else {
            Swift.print("Warning: Invalidation already triggered")
            return
        }

        // 1. Prepare to invalidate (subclass customization point)
        beginLayoutInvalidation()

        // 2. Freeze event holders
        var holdersToFreeze = controller.eventHolders
        // Exclude event view being dragged (already frozen)
        if let draggedView = eventViewBeingDragged, let idx = holdersToFreeze.index(of: draggedView.eventHolder) {
            holdersToFreeze.remove(at: idx)
        }
        // Freeze the event holders in preparation for invalidation
        holdersToFreeze.forEach { $0.freeze() }

        // 3. Perform invalidation by calling self.invalidateLayout(for: each individual event view).
        eventViews.forEach { invalidateLayout(for: $0) }

        // 4. Unfreeze event holders once layout is invalidated
        holdersToFreeze.forEach { $0.unfreeze() }

        // 5. Mark self as needing layout
        needsLayout = true

        // 6. Animate if requested
        if animated {
            NSAnimationContext.runAnimationGroup({ [unowned self] (context) in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                self.layoutSubtreeIfNeeded()
            }, completionHandler: nil)
        }

        // 7. Finish (subclass customization point)
        endLayoutInvalidation()
    }

    /// A convenience method to trigger layout invalidation for all event views.
    ///
    /// - Parameter animated: Pass true to perform an animated subview layout.
    open func invalidateLayoutForAllEventViews(animated: Bool = false) {
        invalidateLayout(for: eventViews, animated: animated)
    }

    // MARK: - Event coloring

    /// The color style used to draw the different event views. Setting this
    /// value to a different style marks event views as needing display.
    @objc public var colorMode: SCKEventColorMode = .byEventKind {
        didSet {
            if colorMode != oldValue {
                for eventView in eventViews {
                    eventView.backgroundColor = nil
                    eventView.reducedEmphasisBackgroundColor = nil
                    eventView.overlayColor = nil
                    eventView.reducedEmphasisOverlayColor = nil
                    eventView.needsDisplay = true
                }
            }
        }
    }

    // MARK: - Event selection

    /// The currently selected event view or `nil` if none. Setting this value may
    /// trigger the `scheduleControllerDidClearSelection(_:)` and/or the
    /// `scheduleController(_:didSelectEvent:)` methods on the controller`s event
    /// manager when appropiate. In addition, it marks all event views as needing
    /// display in order to make them reflect the current selection.
    open weak var selectedEventView: SCKEventView? {
        willSet {
            self.willSetSelectedEventView(newValue: newValue)
        }
        didSet {
            self.didSetSelectedEventView(newValue: self.selectedEventView)
        }
    }

    private var isBlockingSelectionDelegateCalling: Bool = false
    // Updates the event view object without calling cascading delegates
    open func safeUpdateSelectedEventView(_ newValue: SCKEventView?, shouldCallDelegates: Bool) {
        // Unblock delegate calling if needed
        if (!shouldCallDelegates) {
            self.isBlockingSelectionDelegateCalling = true
        }
        self.selectedEventView = newValue
        // Unblock delegate calling if needed
        if (!shouldCallDelegates && self.isBlockingSelectionDelegateCalling) {
            self.isBlockingSelectionDelegateCalling = false
        }
    }

    open func willSetSelectedEventView(newValue: SCKEventView?, shouldCallDelegates: Bool = true) {
        if selectedEventView != nil && newValue == nil {
            if (shouldCallDelegates && !self.isBlockingSelectionDelegateCalling) {
                controller.eventManager?.scheduleControllerDidClearSelection(controller)
            }
        }
    }
    open func didSetSelectedEventView(newValue: SCKEventView?, shouldCallDelegates: Bool = true) {
        for eventView in eventViews {
            eventView.needsDisplay = true
        }
        if let s = selectedEventView, let eM = controller.eventManager {
            //Event view has already checked if `s` was the same as old value.
            if (shouldCallDelegates && !self.isBlockingSelectionDelegateCalling) {
                let theEvent = s.eventHolder.representedObject
                eM.scheduleController(controller, didSelectEvent: theEvent)
            }
        }
    }


    open func select(event: SCKEvent, shouldCallDelegates: Bool) {
        if let validEventViewIndex = self.eventViews.index(where: { $0.eventHolder.representedObject == event }) {
            self.select(withEventIndex: validEventViewIndex, shouldCallDelegates: shouldCallDelegates)
        }
        else {
            // Couldn't find event view representing this event
            self.safeUpdateSelectedEventView(nil, shouldCallDelegates: shouldCallDelegates)
        }
    }

    open func select(withEventIndex index: Int, shouldCallDelegates: Bool) {
        if (index >= 0) && (index < self.eventViews.count) {
            self.safeUpdateSelectedEventView(self.eventViews[index], shouldCallDelegates: shouldCallDelegates)
        }
        else {
            self.safeUpdateSelectedEventView(nil, shouldCallDelegates: shouldCallDelegates)
        }
    }

    open func clearSelection(shouldCallDelegates: Bool) {
        self.safeUpdateSelectedEventView(nil, shouldCallDelegates: shouldCallDelegates)
    }



    open override func mouseDown(with event: NSEvent) {
        // Called when user clicks on an empty space.
        // Deselect selected event view if any
        selectedEventView = nil
        // If double clicked on valid coordinates, notify the event manager's delegate.
        if event.clickCount == 2 {
            let loc = convert(event.locationInWindow, from: nil)
            let offset = relativeTimeLocation(for: loc)
            if offset != SCKRelativeTimeLocationInvalid, let eM = controller.eventManager {
                let blankDate = calculateDate(for: offset)!
                eM.scheduleController(controller, didDoubleClickBlankDate: blankDate)
            }
        }
    }

    // MARK: - Drag & drop support

    /// When dragging, the subview being dragged.
    internal weak var eventViewBeingDragged: SCKEventView?

    internal func prepareForDragging() {
    }

    /// Called by an `SCKEventView` when a drag operation begins. This method
    /// sets the `eventViewBeingDragged` property and freezes the event view's
    /// holder to guarantee that its data remains consistent during the whole 
    /// process even if the represented object properties change.
    ///
    /// - Parameter eventView: The event view being dragged.
    internal final func beginDragging(eventView: SCKEventView) {
        eventViewBeingDragged = eventView
        eventView.eventHolder.freeze()
        prepareForDragging()
    }

    /// Called by an `SCKEventView` every time that `mouseDragged(_:)` is called.
    /// Performs a layout invalidation to handle new conflicts, applies layout and 
    /// marks the schedule view as needing display.
    internal final func continueDragging() {
        invalidateLayoutForAllEventViews()
        layoutSubtreeIfNeeded()
        needsDisplay = true
    }

    /// Called by an `SCKEventView` when a drag operation ends. This method sets
    /// the `eventViewBeingDragged` property to nil, unfreezes the draged view's
    /// event holder and triggers a final layout invalidation and drawing for this
    /// instance.
    internal final func endDragging() {
        guard let draggedEventView = eventViewBeingDragged else {
            Swift.print("Called endDragging() without an event view being dragged")
            return
        }
        draggedEventView.eventHolder.unfreeze()
        eventViewBeingDragged = nil
        invalidateLayoutForAllEventViews(animated: true)
        restoreAfterDragging()
        needsDisplay = true
    }

    internal func restoreAfterDragging() {
    }
}
