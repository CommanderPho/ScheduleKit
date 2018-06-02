/*
 *  SCKEventView.swift
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

/// The view class used by ScheduleKit to display each event in a schedule view.
/// This view is responsible of managing a descriptive label and also of handling
/// mouse events, including drag and drop operations, which may derive in changes
/// to the represented event.
@objc open class SCKEventView: NSView {

    /// The event holder represented by this view.
    open var eventHolder: SCKEventHolder! {
        didSet {
            innerLabel.stringValue = eventHolder.cachedTitle
            innerLabel.textColor = self.labelTextColor
            innerLabel.font = self.innerLabelFont
        }
    }

    /// A label that displays the represented event's title or its duration when
    /// dragging the view from the bottom edge. The title value is updated
    /// automatically by the event holder when a change in the event's title is 
    /// observed.
    open var innerLabel: SCKTextField = {
        let _label = SCKTextField(frame: .zero)
        _label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 249), for: .horizontal)
        _label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 249), for: .vertical)
        _label.autoresizingMask = [.width, .height]
        return _label
    }()

    open var innerLabelFont: NSFont = NSFont.systemFont(ofSize: 12.0)  {
        didSet {
            self.innerLabel.font = self.innerLabelFont
            self.innerLabel.setNeedsDisplay()
        }
    }

    // MARK: - Drawing

    /// A cached copy of the last used background color to increase drawing
    /// performance. Invalidated when the schedule view's color mode changes or
    /// when the event's user or user event color changes in .byEventOwner mode.
    internal var backgroundColor: NSColor?
    internal var reducedEmphasisBackgroundColor: NSColor?

    /// A cached copy of the last used text colors to increase drawing
    /// performance. Invalidated when the schedule view's color mode changes or
    /// when the event's user or user event color changes in .byEventOwner mode.
    internal var overlayColor: NSColor? {
        didSet {
            self.updateOverlayColor()
        }
    }
    internal var reducedEmphasisOverlayColor: NSColor? {
        didSet {
            self.updateOverlayColor()
        }
    }

    public var needsTimeSubindicatorLine: Bool {
        guard let validConfig = self.timeSubindicatorConfig else { return false }
//        return validConfig.shouldDisplay
        return true
    }

    public var timeSubindicatorConfig: SCKEventTimeSubindicatorConfig? = nil {
        didSet {
            self.needsDisplay = true
        }
    }

    //internal var timeSubindicatorLineConfig

    public func drawTimeSubindicatorLine(_ dirtyRect: CGRect) {
        guard let validConfig = self.timeSubindicatorConfig else { return }
        //let currentSize = self.frame.size
        let currentSize = dirtyRect.size
        let verticalOffset: CGFloat = currentSize.height * validConfig.eventViewRelativeOffset
        let maxHorizontalOffset: CGFloat = currentSize.width * validConfig.height

        //Finalize Position, we move none on the x axis (drawing a vertical line)
        let startPointPosition: CGPoint = CGPoint(x: 0, y: verticalOffset)
        let endPointPosition: CGPoint = CGPoint(x: currentSize.width, y: verticalOffset)

        let path = NSBezierPath.init()

        path.lineWidth = validConfig.thickness

        // move to starting point on line (defined origin)
        path.move(to: startPointPosition)
        // draw line of required length
        path.line(to: endPointPosition)

        let finalStrokeColor: NSColor
        if let validColor = validConfig.color {
            finalStrokeColor = validColor
        }
        else {
            finalStrokeColor = self.overlayColor ?? self.scheduleView.defaultEventOverlayColor
        }
        finalStrokeColor.setStroke()
        path.stroke()
    }

    public var labelTextColor: NSColor {
        let isAnyViewSelected = (scheduleView.selectedEventView != nil)
        let isThisViewSelected = (scheduleView.selectedEventView == self)
        var currentOverlayColor: NSColor
        if isAnyViewSelected && !isThisViewSelected {
            // Set to reducedEmphasisOverlayColor when another event is selected
            if reducedEmphasisOverlayColor == nil {
                switch scheduleView.colorMode {
                case .byEventKind:
                    let kind = eventHolder.representedObject.eventKind
                    let color = scheduleView.delegate?.reducedEmphasisOverlayColor?(for: kind, in: scheduleView)
                    reducedEmphasisOverlayColor = color ?? scheduleView.defaultEventReducedEmphasisOverlayColor
                case .byEventOwner:
                    let color = eventHolder.cachedUser?.reducedEmphasisEventColor
                    reducedEmphasisOverlayColor = color ?? scheduleView.defaultEventReducedEmphasisOverlayColor
                }
            }
            currentOverlayColor = reducedEmphasisOverlayColor!

        } else {
            // No view selected or this view selected.
            if overlayColor == nil {
                switch scheduleView.colorMode {
                case .byEventKind:
                    let kind = eventHolder.representedObject.eventKind
                    let color = scheduleView.delegate?.overlayColor?(for: kind, in: scheduleView)
                    overlayColor = color ?? scheduleView.defaultEventOverlayColor
                case .byEventOwner:
                    let color = eventHolder.cachedUser?.eventOverlayColor
                    overlayColor = color ?? scheduleView.defaultEventOverlayColor
                }
            }
            currentOverlayColor = overlayColor!
        }
        return currentOverlayColor
    }

    public func updateOverlayColor() {
        self.innerLabel.textColor = self.labelTextColor
        self.innerLabel.setNeedsDisplay()
    }


    open var isSelected: Bool {
        get {
            return (scheduleView.selectedEventView == self)
        }
        set {
            // Select this view if not selected yet. This will trigger selection
            // methods on the controller's delegate.
            if scheduleView.selectedEventView != self {
                scheduleView.safeUpdateSelectedEventView(self, shouldCallDelegates: true)
            }
        }
    }

    // Rediced Emphasis is a "greying out" to indicate that this EventView is not the focused event view, while a different one is.
    open var isReducedEmphasis: Bool {
        let isAnyViewSelected = (scheduleView.selectedEventView != nil)
        let isThisViewSelected = self.isSelected
        return (isAnyViewSelected && !isThisViewSelected)
    }


    open override func draw(_ dirtyRect: CGRect) {
        var fillColor: NSColor
        if self.isReducedEmphasis {
            // Set color to reducedEmphasisBackgroundColor when another event is selected
            if reducedEmphasisBackgroundColor == nil {
                switch scheduleView.colorMode {
                case .byEventKind:
                    let kind = eventHolder.representedObject.eventKind
                    let color = scheduleView.delegate?.reducedEmphasisColor?(for: kind, in: scheduleView)
                    reducedEmphasisBackgroundColor = color ?? scheduleView.defaultEventReducedEmphasisBackgroundColor
                case .byEventOwner:
                    let color = eventHolder.cachedUser?.reducedEmphasisEventColor
                    reducedEmphasisBackgroundColor = color ?? scheduleView.defaultEventReducedEmphasisBackgroundColor
                }
            }
            fillColor = reducedEmphasisBackgroundColor!

        } else {
            // No view selected or this view selected. Let's determine background
            // color.
            if backgroundColor == nil {
                switch scheduleView.colorMode {
                case .byEventKind:
                    let kind = eventHolder.representedObject.eventKind
                    let color = scheduleView.delegate?.color?(for: kind, in: scheduleView)
                    backgroundColor = color ?? scheduleView.defaultEventBackgroundColor
                case .byEventOwner:
                    let color = eventHolder.cachedUser?.eventColor
                    backgroundColor = color ?? scheduleView.defaultEventBackgroundColor
                }
            }
            fillColor = backgroundColor!
        }

        // Make more transparent if dragging this view.
        if self.isSelected, case .draggingContent(_, _, _) = draggingStatus {
            fillColor = fillColor.withAlphaComponent(0.7)
        }

        let wholeRect = CGRect(origin: CGPoint.zero, size: frame.size)
        if inLiveResize {
            fillColor.set()
            wholeRect.fill()
        } else {
            fillColor.setFill()
            let path = NSBezierPath(roundedRect: wholeRect, xRadius: 2.0, yRadius: 2.0)
            if scheduleView.contentRect.origin.y > scheduleView.convert(frame.origin, from: self).y
                || scheduleView.contentRect.maxY < frame.maxY {
                fillColor.withAlphaComponent(0.2).setFill()
            }
            path.fill()
        }

        if (self.needsTimeSubindicatorLine) {
            self.drawTimeSubindicatorLine(dirtyRect)
        }
    }

    // MARK: - View lifecycle

    /// The `SCKView` instance to which this view has been added.
    public weak var scheduleView: SCKView!

    open override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        needsDisplay = true
    }

    open override func viewDidMoveToSuperview() {
        self.scheduleView = superview as? SCKView
        // Add the title label to the view hierarchy.
        if superview != nil && innerLabel.superview == nil {
            self.innerLabel.frame = CGRect(origin: .zero, size: frame.size)
            self.addSubview(self.innerLabel)
        }
        if superview != nil {
            let newTrackingArea = NSTrackingArea(rect: self.bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
            self.addTrackingArea(newTrackingArea)
        }
    }

    // MARK: - Overrides

    open override var isFlipped: Bool {
        return true
    }

    open override func resetCursorRects() {
        let r = NSRect(x: 0, y: frame.height-2.0, width: frame.width, height: 4.0)
        addCursorRect(r, cursor: .resizeUpDown)
    }

    // MARK: - Mouse events and dragging

    open override func mouseDown(with event: NSEvent) {
        self.isSelected = true
    }

    // MARK: Dragging

    /// A type to describe the drag & drop state of an `SCKEventView`.
    ///
    /// - idle: The view is not being dragged yet.
    /// - draggingDuration: The view is being stretched vertically.
    /// - draggingContent: The view is being moved to another position.
    public enum Status {
        case idle
        case draggingDuration(oldValue: Int, lastValue: Int)
        case draggingContent(
            oldStart: SCKRelativeTimeLocation,
            newStart: SCKRelativeTimeLocation,
            innerDelta: CGFloat
        )
    }

    /// The view's drag and drop state.
    public var draggingStatus: Status = .idle

    open override func mouseDragged(with event: NSEvent) {
        switch draggingStatus {
        // User began dragging from bottom
        case .idle where NSCursor.current == NSCursor.resizeUpDown:
            draggingStatus = .draggingDuration(oldValue: eventHolder.cachedDuration,
                                              lastValue: eventHolder.cachedDuration)
            scheduleView.beginDragging(eventView: self)
            parseDurationDrag(with: event)
        // User continued dragging
        case .draggingDuration:
            parseDurationDrag(with: event)
        default:
            // User began dragging from center
            if case .idle = draggingStatus {
                draggingStatus = .draggingContent(oldStart: eventHolder.relativeStart,
                                                  newStart: eventHolder.relativeStart,
                                                  innerDelta: convert(event.locationInWindow, from: nil).y)
                scheduleView.beginDragging(eventView: self)
            }
            // User continued dragging (and fallthrough)
            parseContentDrag(with: event)
        }
        scheduleView.continueDragging()
    }

    open func parseDurationDrag(with event: NSEvent) {
        guard case .draggingDuration(let old, let last) = draggingStatus else {
            return
        }

        let superLoc = scheduleView.convert(event.locationInWindow, from: nil)
        let sDate = eventHolder.cachedScheduledDate
        if let eDate = scheduleView.calculateDate(for: scheduleView.relativeTimeLocation(for: superLoc)) {
            var newDuration = Int(trunc((eDate.timeIntervalSince(sDate) / 60.0)))
            if newDuration != last {
                if newDuration >= 5 {
                    eventHolder.cachedDuration = newDuration
                    let inSeconds = newDuration * 60
                    let endDate = eventHolder.cachedScheduledDate.addingTimeInterval(Double(inSeconds))
                    var relativeEnd = scheduleView.calculateRelativeTimeLocation(for: endDate)
                    if relativeEnd == Double(NSNotFound) {
                        relativeEnd = 1.0
                    }
                    eventHolder.relativeLength = relativeEnd - eventHolder.relativeStart
                    scheduleView.invalidateLayout(for: self)
                } else {
                    newDuration = 5
                }
                innerLabel.stringValue = "\(newDuration) min"
                //Update context
                draggingStatus = .draggingDuration(oldValue: old, lastValue: newDuration)
            }
        }
    }

    open func parseContentDrag(with event: NSEvent) {
        guard case .draggingContent(let old, _, let delta) = draggingStatus else {
            return
        }

        var tPoint = scheduleView.convert(event.locationInWindow, from: nil)
        tPoint.y -= delta

        var newStartLoc = scheduleView.relativeTimeLocation(for: tPoint)
        if newStartLoc == SCKRelativeTimeLocationInvalid && tPoint.y < scheduleView.frame.midY {
            //May be too close to an edge, check if too low
            tPoint.y = scheduleView.contentRect.minY
            newStartLoc = scheduleView.relativeTimeLocation(for: tPoint)
        }
        if newStartLoc != SCKRelativeTimeLocationInvalid {
            tPoint.y += frame.height
            let newEndLoc = scheduleView.relativeTimeLocation(for: tPoint)
            if newEndLoc != SCKRelativeTimeLocationInvalid {
                eventHolder.relativeStart = newStartLoc
                eventHolder.relativeEnd = newEndLoc
                eventHolder.cachedScheduledDate = scheduleView.calculateDate(for: newStartLoc)!
                draggingStatus = .draggingContent(oldStart: old, newStart: newStartLoc, innerDelta: delta)
            }
        }
    }

    // MARK: Mouse up

    open override func mouseUp(with event: NSEvent) {
        switch draggingStatus {
        case .draggingDuration(let old, let new):

            // Restore title 
            innerLabel.stringValue = eventHolder.cachedTitle
            let event = eventHolder.representedObject
            var shouldContinue = true
            if let eventManager = scheduleView.controller.eventManager {
                shouldContinue = eventManager.scheduleController(scheduleView.controller,
                                                                 shouldChangeDurationOfEvent: event,
                                                                 from: old,
                                                                 to: new)
            }
            if shouldContinue {
                commitDraggingOperation {
                    event.duration = new
                }
            } else {
                eventHolder.cachedDuration = old
                flushUncommitedDraggingOperation()
            }

            scheduleView.endDragging()

        case .draggingContent(let oldStart, let newStart, _):
            if let scheduledDate = scheduleView.calculateDate(for: newStart) {
                let event = eventHolder.representedObject
                var shouldContinue = true
                if let eventManager = scheduleView.controller.eventManager {
                    shouldContinue = eventManager.scheduleController(scheduleView.controller,
                                                                     shouldChangeDateOfEvent: event,
                                                                     from: eventHolder.representedObject.scheduledDate,
                                                                     to: scheduledDate)
                }
                if shouldContinue {
                    commitDraggingOperation {
                        event.scheduledDate = scheduledDate
                    }
                } else {
                    let oldDate = scheduleView.calculateDate(for: oldStart)!
                    eventHolder.cachedScheduledDate = oldDate
                    flushUncommitedDraggingOperation()
                }
            }
            scheduleView.endDragging()

        case .idle where event.clickCount == 2:
            scheduleView.controller.eventManager?.scheduleController(scheduleView.controller, didDoubleClickEvent: eventHolder.representedObject)
        default: break
        }
        draggingStatus = .idle
        needsDisplay = true
    }

    open func commitDraggingOperation(withChanges closure: () -> Void) {
        eventHolder.stopObservingRepresentedObjectChanges()
        closure()
        eventHolder.resumeObservingRepresentedObjectChanges()
        eventHolder.recalculateRelativeValues()
        // FIXME: needed? will be called from endDraggingEventView
        scheduleView.invalidateLayoutForAllEventViews()
    }

    open func flushUncommitedDraggingOperation() {
        eventHolder.recalculateRelativeValues()
        scheduleView.invalidateLayout(for: self)
    }

    // MARK: Right mouse events

    open override func menu(for event: NSEvent) -> NSMenu? {
        guard let c = scheduleView.controller, let eM = c.eventManager else {
            return nil
        }
        return eM.scheduleController(c, menuForEvent: eventHolder.representedObject)
    }

    open override func rightMouseDown(with event: NSEvent) {
        // Select the event if not selected and continue showing the contextual
        // menu if any.
        if scheduleView.selectedEventView != self {
            scheduleView.safeUpdateSelectedEventView(self, shouldCallDelegates: true)
//            scheduleView.selectedEventView = self
        }
        super.rightMouseDown(with: event)
    }


    open override func mouseEntered(with event: NSEvent) {
        debugPrint("mouseEntered: ")
        guard let validTrackingArea = event.trackingArea else {
            debugPrint("No tracking area found!")
            return super.mouseEntered(with: event)
        }
        if (self.trackingAreas.contains(validTrackingArea)) {
            debugPrint("day")
            self.isSelected = true

        }
        else {
            return super.mouseEntered(with: event)
        }
    }

    open override func mouseExited(with event: NSEvent) {
        debugPrint("mouseExited: ")
        guard let validTrackingArea = event.trackingArea else {
            debugPrint("No tracking area found!")
            return super.mouseExited(with: event)
        }
        if (self.trackingAreas.contains(validTrackingArea)) {
            debugPrint("day")
            self.isSelected = false
            
        }
        else {
            return super.mouseExited(with: event)
        }
    }


}
