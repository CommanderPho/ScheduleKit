/*
 *  SCKGridView.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 28/10/2016.
 *  Copyright:  © 2016-2017 Guillem Servera (https://github.com/gservera)
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

/// An abstract `SCKView` subclass that implements the common functionality of any
/// grid-style schedule view, such as the built in day view and week view. This 
/// class provides conflict management, interaction with the displayed days and 
/// hours, displaying unavailable time intervals and a zoom feature. 
///
/// It also manages a series of day, month, hour and hour fraction labels, which 
/// are automatically updated and laid out by this class.
///
/// - Note: Do not instantiate this class directly.
///
open class SCKGridView: SCKView {
//


    var Constants: SCKLayoutConstants {
        guard let validLayoutDelegate = self.layoutManagingDelegate else {
            return SCKLayoutConstants(DayAreaHeight: 40.0, DayAreaMarginBottom: 40.0, MaxHeightPerHour: 300.0, HourAreaWidth: 56.0)
        }
        return validLayoutDelegate.layoutConstants
    }


    public var unavailableTimeRangesColor: NSColor { return self.colorManagingDelegate?.unavailableTimeRangesColor ?? NSColor(red: 0.925, green: 0.942, blue: 0.953, alpha: 1.0) }
    public var dayDelimetersColor: NSColor { return self.colorManagingDelegate?.dayDelimetersColor ?? NSColor(deviceWhite: 0.95, alpha: 1.0) }
    public var hourDelimetersColor: NSColor { return self.colorManagingDelegate?.hourDelimetersColor ?? NSColor(deviceWhite: 0.95, alpha: 1.0) }
    public var currentTimeLineColor: NSColor { return self.colorManagingDelegate?.currentTimeLineColor ?? NSColor.red }


    override func setUp() {
        super.setUp()
        updateHourParameters()
    }

    override open weak var delegate: SCKViewDelegate? {
        didSet {
            readDefaultsFromDelegate()
        }
    }

    override open weak var colorManagingDelegate: SCKColorManaging? {
        didSet {
            self.setUp()
        }
    }

    override open weak var labelManagingDelegate: SCKLabelManaging? {
        didSet {
            self.setUp()
            self.resetLabels(andConfigure: true)
        }
    }

    override open weak var layoutManagingDelegate: SCKLayoutManaging? {
        didSet {
            self.setUp()
        }
    }

    // MARK: - Date handling additions

    open override var dateInterval: DateInterval {
        didSet { // Set up day count and day labels
            let sD = dateInterval.start
            let eD = dateInterval.end.addingTimeInterval(1)
            self.dayCount = sharedCalendar.dateComponents([.day], from: sD, to: eD).day!
            configureDayLabels()
            _ = self.minuteTimer
        }
    }

    /// The number of days displayed. Updated by changing `dateInterval`.
    private(set) var dayCount: Int = 0

    /// A value representing the day start hour.
    private var dayStartPoint = SCKDayPoint.zero

    /// A view representign the day end hour.
    private var dayEndPoint = SCKDayPoint(hour: 24, minute: 0, second: 0)

    /// Called when the `dayStartPoint` and `dayEndPoint` change during
    /// initialisation or when their values are read from the delegate. Sets the
    /// `firstHour` and `hourCount` properties and ensures a minimum height per hour
    /// to fill the view.
    private func updateHourParameters() {
        firstHour = dayStartPoint.hour
        hourCount = dayEndPoint.hour - dayStartPoint.hour
        //TODO: Doesn't this contentRect.height need to be reduced by the margin sizes? Is this responsible for the layout bug?
        let minHourHeight = contentRect.height / CGFloat(hourCount)
        if hourHeight < minHourHeight {
            hourHeight = minHourHeight
        }
    }

    /// The first hour of the day displayed.
    internal var firstHour: Int = 0 {
        didSet { configureHourLabels() }
    }

    /// The total number of hours displayed.
    internal var hourCount: Int = 1 {
        didSet { configureHourLabels() }
    }

    /// The height for each hour row. Setting this value updated the saved one in
    /// UserDefaults and updates hour labels visibility. 
    internal var hourHeight: CGFloat = 0.0 {
        didSet {
            if hourHeight != oldValue && superview != nil {
                let key = SCKGridView.defaultsZoomKeyPrefix + ".\(type(of: self))"
                UserDefaults.standard.set(hourHeight, forKey: key)
                invalidateIntrinsicContentSize()
            }
            updateHourLabelsVisibility()
        }
    }

    // MARK: - Day and hour labels

    private func label(_ text: String, size: CGFloat, color: NSColor) -> NSTextField {
        let label = NSTextField(frame: .zero)
        label.isBordered = false; label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        label.stringValue = text
        label.font = .systemFont(ofSize: size)
        label.textColor = color
        label.setAccessibilityIdentifier("SCKDayOrHourLabel")
        label.sizeToFit() // Needed
        return label
    }

    func resetHourLabels(andConfigure shouldConfigure: Bool) {
        // Remove all hour and minute labels
        for (hour, label) in self.hourLabels {
            let shouldBeInstalled = false
            if label.superview != nil && !shouldBeInstalled {
                label.removeFromSuperview()
                for min in [10, 15, 20, 30, 40, 45, 50] {
                    hourLabels[min*10+hour]?.removeFromSuperview()
                }
            }
        }
        self.hourLabels.removeAll(keepingCapacity: true)
        if (shouldConfigure) {
            self.configureHourLabels()
        }
    }

    func resetDayLabels(andConfigure shouldConfigure: Bool) {
        //Remove all Day and Month labels
        for (day, dayLabel) in dayLabels.enumerated() {
            if dayLabel.superview != nil {
                dayLabel.removeFromSuperview()
                self.monthLabels[day].removeFromSuperview()
            }
        }
        self.dayLabels.removeAll(keepingCapacity: true)
        self.monthLabels.removeAll(keepingCapacity: true)

        // Determine if the day/month labels should be reconfigured (reinitialized and added to the views) based on the passed in parameter and whether the labelManagingDelegate says we should display them.
        let finalShouldConfigure: Bool
        if let validLabelDelegate = self.labelManagingDelegate {
            finalShouldConfigure = (shouldConfigure && (!validLabelDelegate.shouldDisableDayHeaderLabels))
        }
        else {
            finalShouldConfigure = shouldConfigure
        }

        if (finalShouldConfigure) {
            self.configureDayLabels()
        }
    }

    func resetLabels(andConfigure shouldConfigure: Bool) {
        self.resetDayLabels(andConfigure: shouldConfigure)
        self.resetHourLabels(andConfigure: shouldConfigure)
    }




    // MARK: Day and month labels

    /// An array containing all generated day labels.
    private var dayLabels: [NSTextField] = []

    /// An array containing all generated month labels.
    private var monthLabels: [NSTextField] = []

    /// A container view for day labels. Pinned at the top of the scroll view.
    private let dayLabelingView = NSView(frame: .zero)

    // The rectangles that wrap all the events in the day
    private var dayColumnRectangles: [CGRect] = []


    public func getDayLabelingView() -> NSView {
        return self.dayLabelingView
    }

    public func getTopLabels() -> (day: [NSTextField], month: [NSTextField]) {
        return (self.dayLabels, self.monthLabels)
    }

    public func getGridColumnRectangles() -> [CGRect] {
        return self.dayColumnRectangles
    }



    /// A date formatter for day labels.
    private var dayLabelsDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE d"; return f
    }()

    /// A date formatter for month labels.
    private var monthLabelsDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f
    }()

    /// Generates all the day and month labels for the displayed day range
    /// which have not been generated yet and installs them as subviews of this
    /// view, while also removing the unneeded ones from its superview. This
    /// method also updates the label's string value to match the displayed date
    /// interval. Eventually marks the view as needing layout. This method is 
    /// called whenever the day interval property changes.
    private func configureDayLabels() {

        // Determine if the day/month labels should be reconfigured (reinitialized and added to the views) based on the passed in parameter and whether the labelManagingDelegate says we should display them.
        let labelsAreEnabled: Bool
        if let validLabelDelegate = self.labelManagingDelegate {
            labelsAreEnabled = (!validLabelDelegate.shouldDisableDayHeaderLabels)
        }
        else {
            labelsAreEnabled = true
        }

        // If labels are not enabled, we reset them (removing them from the views and deallocating them) without configuring them (as not to recreate them)
        if (!labelsAreEnabled) {
            self.resetDayLabels(andConfigure: false)
            needsLayout = true
            return
        }

        // 1. Generate missing labels
        for day in 0..<dayCount {
            if dayLabels.count > day { // Skip already created labels
                continue
            }
            let dayLabel: NSTextField
            let monthLabel: NSTextField

            if let validLabelDelegate = self.labelManagingDelegate {
                dayLabel = validLabelDelegate.getLabel(forLabelType: .day(date: nil))
                monthLabel = validLabelDelegate.getLabel(forLabelType: .month(date: nil))
            }
            else {
                dayLabel = label("", size: 14.0, color: .darkGray)
                monthLabel = label("", size: 12.0, color: .lightGray)
            }
            monthLabel.isHidden = true
            dayLabels.append(dayLabel)
            monthLabels.append(monthLabel)
        }

        // 2. Add visible days' labels as subviews. Remove others if installed.
        // In addition, change label string values to the correct ones.
        for (day, dayLabel) in dayLabels.enumerated() {
            if dayLabel.superview != nil && day >= dayCount {
                dayLabel.removeFromSuperview()
                monthLabels[day].removeFromSuperview()
            } else if day < dayCount {
                if dayLabel.superview == nil {
                    self.dayLabelingView.addSubview(dayLabel)
                    self.dayLabelingView.addSubview(monthLabels[day])
                }
                let date = sharedCalendar.date(byAdding: .day, value: day, to: dateInterval.start)!
                let text: String
                if let validLabelDelegate = self.labelManagingDelegate {
                    text = validLabelDelegate.getLabelText(forLabelType: .day(date: date))
                }
                else {
                    text = dayLabelsDateFormatter.string(from: date).uppercased()
                }
                dayLabel.stringValue = text
                dayLabel.sizeToFit()

                // Show month label if first day in week or first day in month.
                if day == 0 || sharedCalendar.component(.day, from: date) == 1 {
                    let monthText: String
                    if let validLabelDelegate = self.labelManagingDelegate {
                        monthText = validLabelDelegate.getLabelText(forLabelType: .month(date: date))
                    }
                    else {
                        monthText = monthLabelsDateFormatter.string(from: date)
                    }
                    monthLabels[day].stringValue = monthText
                    monthLabels[day].sizeToFit()
                    monthLabels[day].isHidden = false
                } else {
                    monthLabels[day].isHidden = true
                }
            }
        }
        // 3. Set needs layout
        needsLayout = true
    }

    // MARK: Hour labels

    /// A dictionary containing all generated hour labels stored using the hour
    /// as the key for n:00 labels and the hour plus 100*m for n:m labels.
    private var hourLabels: [Int: NSTextField] = [:]

    /// Generates all the hour and minute labels for the displayed hour range which have not been generated yet and
    /// installs them as subviews of this view, while also removing the unneeded ones from its superview. Eventually
    /// marks the view as needing layout. This method is called when the first hour or the hour count properties change.
    private func configureHourLabels() {
        // 1. Generate missing hour labels
        for hourIdx in 0..<hourCount {
            let hour = firstHour + hourIdx
            if hourLabels[hour] != nil {
                continue
            }
            let hourLabel: NSTextField
            if let validLabelDelegate = self.labelManagingDelegate {
                hourLabel = validLabelDelegate.getLabel(forLabelType: .hour(hourValue: hour))
            }
            else {
                hourLabel = label("\(hour):00", size: 11, color: .darkGray)
            }
            hourLabels[hour] = hourLabel
            for min in [10, 15, 20, 30, 40, 45, 50] {
                let mLabel: NSTextField
                if let validLabelDelegate = self.labelManagingDelegate {
                    mLabel = validLabelDelegate.getLabel(forLabelType: .min(hourValue: hour, minValue: min))
                }
                else {
                    mLabel = label("\(hour):\(min)  -", size: 10, color: .lightGray)
                }
                mLabel.isHidden = true
                hourLabels[hour+min*10] = mLabel
            }
        }

        // 2. Add visible hours' labels as subviews. Remove others if installed.
        for (hour, label) in hourLabels {
            guard hour < 100 else {continue}
            let shouldBeInstalled = (hour >= firstHour && hour < firstHour + hourCount)
            if label.superview != nil && !shouldBeInstalled {
                label.removeFromSuperview()
                for min in [10, 15, 20, 30, 40, 45, 50] {
                    hourLabels[min*10+hour]?.removeFromSuperview()
                }
            } else if label.superview == nil && shouldBeInstalled {
                addSubview(label)
                for min in [10, 15, 20, 30, 40, 45, 50] {
                    guard let mLabel = hourLabels[min*10+hour] else {
                        Swift.print("Warning: An hour label was missing")
                        continue
                    }
                    addSubview(mLabel)
                }
            }
        }

        // 3. Set needs layout
        needsLayout = true
    }

    /// Shows or hides the half hour, quarter hour and 10-minute hour labels 
    /// according to the hour height property. This method is called whenever the
    /// mentioned property changes.
    private func updateHourLabelsVisibility() {
        for (key, value) in hourLabels {
            guard eventViewBeingDragged == nil else {
                value.isHidden = true
                continue
            }
            switch key {
            case 300..<324:                                  value.isHidden = (hourHeight < 40.0)
            case 150..<174, 450..<474:                       value.isHidden = (hourHeight < 80.0 || hourHeight >= 120)
            case 100..<124, 200..<224, 400..<424, 500..<524: value.isHidden = (hourHeight < 120.0)
            default:                                         value.isHidden = false
            }
        }
    }

    // MARK: - Date transform additions

    // Converts between a DateInterval relative time location and a day relative time location
    public final func convertToDayRelative(totalRelativeTimeLocation: SCKRelativeTimeLocation) -> (dayIndex: Int, dayRelative: SCKRelativeTimeLocation)? {
        if (totalRelativeTimeLocation == SCKRelativeTimeLocationInvalid) { return nil }
        // offsetPerDay: Gives the relative offset at the start of each day.
        let offsetPerDay: Double = 1.0 / Double(self.dayCount)
        let totalMinutesPerDay: Double = 60.0 * Double(self.hourCount)
        // day: The integer day index to which the point belongs
        let day: Int = Int(trunc(totalRelativeTimeLocation/offsetPerDay))
        // dayOffset: the accumulated relative offset for the start of the day to which the point belongs
        let dayStartOffset: Double = offsetPerDay * Double(day)

        let remainder: Double = totalRelativeTimeLocation - dayStartOffset
        // inverseResult is in seconds
        let inverseResult: Double = (self.dateInterval.duration * remainder)
        let inverseResultMinutes: Double = inverseResult * Double(60.0)
        let result: SCKRelativeTimeLocation = (inverseResultMinutes / totalMinutesPerDay)
        return (day, result)
    }




//    public final func calculateDayRelativeTimeLocation(for date: Date) -> SCKRelativeTimeLocation {
//        guard dateInterval.contains(date) else { return SCKRelativeTimeLocationInvalid; }
//        let dateRef = date.timeIntervalSinceReferenceDate
//        let startDateRef = dateInterval.start.timeIntervalSinceReferenceDate
//        return (dateRef - startDateRef) / dateInterval.duration
//    }


    // Given any point within the rectangle, determines the time it should occur on.
    override open func relativeTimeLocation(for point: CGPoint) -> Double {
        if contentRect.contains(point) {
            // dayWidth: The screen width of each day
            let dayWidth: CGFloat = contentRect.width / CGFloat(dayCount)
            // offsetPerDay: Gives the relative offset at the start of each day.
            let offsetPerDay = 1.0 / Double(dayCount)
            // day: The integer day index to which the point belongs
            let day = Int(trunc((point.x-contentRect.minX)/dayWidth))
            // dayOffset: the accumulated relative offset for the start of the day to which the point belongs
            let dayOffset = offsetPerDay * Double(day)

            // offsetPerDay: Gives the relative offset (length) for each minute. Note this could be calculated anywhere on the dateInterval and would be the same.
            // Note: addingTimeInterval(60) specifies the 60 seconds in a minute.
            let offsetPerMin = calculateRelativeTimeLocation(for: dateInterval.start.addingTimeInterval(60))
            // offsetPerHour: Gives the relative offset (length) for each hour.
            let offsetPerHour = 60.0 * offsetPerMin
            let totalMinutesPerDay = 60.0 * CGFloat(hourCount)
            let minute = totalMinutesPerDay * (point.y - contentRect.minY) / contentRect.height
            let minuteOffset = offsetPerMin * Double(minute)
            return dayOffset + (offsetPerHour * Double(firstHour)) + minuteOffset
        }
        return SCKRelativeTimeLocationInvalid
    }


    open func relativeScreenHeight(forAbsoluteNumberMinutes absoluteMin: Double) -> CGFloat? {
        let canvas = contentRect
        let dayTotalHours: Double = Double(self.hourCount)
        let dayTotalMinutes: Double = (dayTotalHours * 60.0)
        if (dayTotalMinutes <= 0.0) { return nil }
        let m: Double = (absoluteMin / dayTotalMinutes)
        let relScreenHeight: Double = m
        let absoluteScreenHeight: CGFloat = canvas.height * CGFloat(relScreenHeight)
//        let absoluteOffset: CGFloat = canvas.minY + absoluteScreenHeight
        return absoluteScreenHeight
    }




//    open func relativeScreenHeight(for offset: SCKRelativeTimeLength) -> CGFloat {
//        // offsetPerDay: Gives the relative offset (length) for each minute. Note this could be calculated anywhere on the dateInterval and would be the same.
//        // Note: addingTimeInterval(60) specifies the 60 seconds in a minute.
//        let offsetPerMin = calculateRelativeTimeLocation(for: dateInterval.start.addingTimeInterval(60))
//        return (offsetPerMin * offset)
//    }


    override open func relativeTimeLength(for height: CGFloat) -> SCKRelativeTimeLength {
        let canvas = contentRect
        if (canvas.height < height) { return SCKRelativeTimeLengthInvalid }
        // percentHeight: maps on to a scale of 0.0 - 1.0 for the day
        let percentHeight: Double = Double(height) / Double(canvas.height)
        // Now just convert from day relative to duration relative
        let dayTotalHours: Double = Double(self.hourCount)
        let dayTotalMinutes: Double = (dayTotalHours * 60.0)
        let dayTotalSeconds: Double = (dayTotalMinutes * 60.0)
        if (dayTotalSeconds <= 0.0) { return SCKRelativeTimeLengthInvalid }

        // offsetPerDay: Gives the relative offset at the start of each day.
        let offsetPerDay = 1.0 / Double(dayCount)
        let dateIntervalTotalSeconds = dateInterval.duration
        let result: SCKRelativeTimeLength = (percentHeight * (dayTotalSeconds / dateIntervalTotalSeconds))
        // offsetPerDay: Gives the relative offset (length) for each minute. Note this could be calculated anywhere on the dateInterval and would be the same.
        // Note: addingTimeInterval(60) specifies the 60 seconds in a minute.
//        let offsetPerMin = calculateRelativeTimeLocation(for: dateInterval.start.addingTimeInterval(60))
        return result
    }

    /// Returns the Y-axis position in the view's coordinate system that represents a particular hour and
    /// minute combination.
    /// - Parameters:
    ///   - hour: The hour.
    ///   - m: The minute.
    /// - Returns: The calculated Y position.
    open func yFor(hour: Int, minute: Int) -> CGFloat {
        let canvas = contentRect
        let hours = CGFloat(hourCount)
        let h = CGFloat(hour - firstHour)
        return canvas.minY + canvas.height * (h + CGFloat(minute)/60.0) / hours
    }

    // MARK: - Event Layout overrides

    override open var contentRect: CGRect {
        // Exclude day and hour labeling areas.
        return CGRect(x: Constants.HourAreaWidth, y: Constants.paddingTop,
                      width: frame.width - Constants.HourAreaWidth, height: frame.height - Constants.paddingTop)
    }

    override open func invalidateLayout(for eventView: SCKEventView) {
        // Overriden to manage event conflicts. No need to call super in this case because it does nothing.
        // Gets the conflicts (overlapping events) for this specific eventView
        let conflicts: [SCKEventHolder] = controller.resolvedConflicts(for: eventView.eventHolder)
        if !conflicts.isEmpty {
            eventView.eventHolder.conflictCount = conflicts.count
        } else {
            eventView.eventHolder.conflictCount = 1 //FIXME: Should not get here.
            NSLog("Unexpected behavior")
        }
        eventView.eventHolder.conflictIndex = conflicts.index(where: { $0 === eventView.eventHolder }) ?? 0
    }

    override open func prepareForDragging() {
        updateHourLabelsVisibility()
        super.prepareForDragging()
    }

    override open func restoreAfterDragging() {
        updateHourLabelsVisibility()
        super.restoreAfterDragging()
    }

    // MARK: - NSView overrides

    open override var intrinsicContentSize: NSSize {
        return CGSize(width: NSView.noIntrinsicMetric, height: CGFloat(hourCount) * hourHeight + Constants.paddingTop)
    }

    public var dayLabelsRect: CGRect? {
        let canvas = contentRect
        guard dayCount > 0 else { return nil } // View is not ready
        let marginLeft = self.Constants.paddingLeft
        let dayLabelsRect = CGRect(x: marginLeft, y: 0, width: frame.width-marginLeft, height: Constants.DayAreaHeight)
        return dayLabelsRect
    }

    public var dayWidth: CGFloat? {
        guard let validDayLabelsRect = self.dayLabelsRect else { return nil }
        let dayWidth = validDayLabelsRect.width / CGFloat(dayCount)
        return dayWidth
    }


    //MARK: -
    //MARK: - layout()
    open override func layout() {
        super.layout();
        let canvas: CGRect = contentRect
        guard dayCount > 0 else { return } // View is not ready

        let marginLeft: CGFloat = self.Constants.paddingLeft
        let dayLabelsRect: CGRect = self.dayLabelsRect!
        let dayWidth: CGFloat = self.dayWidth!

        // Layout day labels
        self.layoutDayLabels(canvas: canvas, marginLeft: marginLeft, dayWidth: dayWidth)

        // Layout hour labels
        self.layoutHourLabels(canvas: canvas, marginLeft: marginLeft)

        // Layout events
        let offsetPerDay: Double = 1.0/Double(self.dayCount)
        self.layoutEvents(canvas: canvas, dayWidth: dayWidth, offsetPerDay: offsetPerDay)
    }

    //MARK: -
    //MARK: - layoutDayLabels(...)
    // called only by layout()
    open func layoutDayLabels(canvas: CGRect, marginLeft: CGFloat, dayWidth: CGFloat) {
        self.dayColumnRectangles.removeAll(keepingCapacity: true)

        for day in 0..<dayCount {
            let minX = marginLeft + (CGFloat(day) * dayWidth);
            let midY = Constants.DayAreaHeight/2.0
            // Add the day label rect
            self.dayColumnRectangles.append(CGRect.init(x: minX, y: Constants.paddingTop, width: dayWidth, height: canvas.height))

            // Set up the day/month labels if enabled, otherwise just continue to the next day
            if let validLabelDelegate = self.labelManagingDelegate {
                if (validLabelDelegate.shouldDisableDayHeaderLabels) {
                    continue; // continue without messing around with the day or month labels (as they don't exist)
                }
            }
            let dLabel = dayLabels[day]
            let o = CGPoint(x: minX + dayWidth/2.0 - dLabel.frame.width/2.0, y: midY - dLabel.frame.height/2.0)
            var r = CGRect(origin: o, size: dLabel.frame.size)
            if day == 0 || (Int(dLabel.stringValue.components(separatedBy: " ")[1]) == 1) {
                r.origin.y += 8.0
                let mLabel = monthLabels[day]
                let mOrigin = CGPoint(x: minX + dayWidth/2 - mLabel.frame.width/2, y: midY - mLabel.frame.height/2 - 7)
                mLabel.frame = CGRect(origin: mOrigin, size: mLabel.frame.size)
            }
            dLabel.frame = r
        }
    }

    //MARK: -
    //MARK: - layoutHourLabels(...)
    // called only by layout()
    open func layoutHourLabels(canvas: CGRect, marginLeft: CGFloat) {
        for (i, label) in self.hourLabels {
            let size = label.frame.size
            switch i {
            case 0..<24: // Hour label
                let o = CGPoint(x: marginLeft - size.width - 8, y: canvas.minY + CGFloat(i-firstHour) * hourHeight - 7)
                label.frame = CGRect(origin: o, size: size)
            default: // Get the hour and the minute
                var hour = i; while hour >= 50 { hour -= 50 }
                let hourOffset = canvas.minY + CGFloat(hour - firstHour) * hourHeight
                let o = CGPoint(x: marginLeft-size.width + 4, y: hourOffset+hourHeight * CGFloat((i-hour)/10)/60.0 - 7)
                label.frame = CGRect(origin: o, size: size)
            }
        }
    }

    //MARK: -
    //MARK: - layoutEvents(...)
    // called only by layout()
    open func layoutEvents(canvas: CGRect, dayWidth: CGFloat, offsetPerDay: Double) {
        for eventView in subviews.compactMap({ $0 as? SCKEventView }) where eventView.eventHolder.isReady {
            let holder = eventView.eventHolder!
            let day = Int(trunc(holder.relativeStart/offsetPerDay))
            let sPoint = SCKDayPoint(date: holder.cachedScheduledDate)
            let eMinute = sPoint.minute + holder.cachedDuration
            let ePoint = SCKDayPoint(hour: sPoint.hour, minute: eMinute, second: sPoint.second)
            var newFrame = CGRect.zero
            newFrame.origin.y = yFor(hour: sPoint.hour, minute: sPoint.minute)
            newFrame.size.height = yFor(hour: ePoint.hour, minute: ePoint.minute)-newFrame.minY
            newFrame.size.width = dayWidth / CGFloat(eventView.eventHolder.conflictCount)
            // Divide the space allocated for conflicted events up evenly amongst all the events.
            newFrame.origin.x = canvas.minX + CGFloat(day) * dayWidth + newFrame.width * CGFloat(holder.conflictIndex)
            eventView.frame |= newFrame
        }
    }








    open override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize) // Triggers layout. Try to acommodate hour height.
        let visibleHeight = superview!.frame.height - (Constants.paddingTop + Constants.paddingBottom)
        let contentHeight = CGFloat(hourCount) * hourHeight
        if contentHeight < visibleHeight && hourCount > 0 {
            hourHeight = visibleHeight / CGFloat(hourCount)
        }
    }

    open override func viewWillMove(toSuperview newSuperview: NSView?) {
        // Insert day labeling view
        guard let superview = newSuperview else { return }
        let height = Constants.DayAreaHeight
        if let parent = newSuperview?.superview?.superview {
            dayLabelingView.translatesAutoresizingMaskIntoConstraints = false
            //parent.addSubview(dayLabelingView, positioned: .above, relativeTo: nil)
            parent.addSubview(dayLabelingView, positioned: .above, relativeTo: self)

            if let validColorDelegate = self.colorManagingDelegate {
                dayLabelingView.layer?.backgroundColor = validColorDelegate.dayLabelingViewBackgroundColor.cgColor
            }
            else {
                dayLabelingView.layer?.backgroundColor = NSColor.white.cgColor
            }

            dayLabelingView.layer?.opacity = 0.95
            NSLayoutConstraint.activate([
                dayLabelingView.leftAnchor.constraint(equalTo: parent.leftAnchor),
                dayLabelingView.rightAnchor.constraint(equalTo: parent.rightAnchor),
                dayLabelingView.topAnchor.constraint(equalTo: parent.topAnchor),
                dayLabelingView.heightAnchor.constraint(equalToConstant: height)
            ])
        }

        // Restore zoom if possible
        let zoomKey = SCKGridView.defaultsZoomKeyPrefix + ".\(String(describing: type(of: self)))"
        hourHeight = CGFloat(UserDefaults.standard.double(forKey: zoomKey))
        let minHourHeight = (superview.frame.height-Constants.paddingTop)/CGFloat(hourCount)
        if hourHeight < minHourHeight || hourHeight > 1000.0 {
            hourHeight = minHourHeight
        }
    }

    // MARK: - Delegate defaults

    /// Calls some of the delegate methods to reflect user preferences. The default implementation asks for
    /// unavailable time ranges and day start/end hours. Subclasses may override this method to set up additional
    /// parameters by importing settings from their delegate objects. This method is called when the view is set
    /// up and when the `invalidateUserDefaults()` method is called. You should not call this method directly.
    internal func readDefaultsFromDelegate() {
        guard let delegate = delegate as? SCKGridViewDelegate else { return }
        if let unavailableRanges = delegate.unavailableTimeRanges?(for: self) {
            unavailableTimeRanges = unavailableRanges
            needsDisplay = true
        }
        let start = delegate.dayStartHour(for: self)
        var end = delegate.dayEndHour(for: self)
        if end == 0 { end = 24 }

        if let layoutDelegate = self.layoutManagingDelegate {

        }
        if let labelDelegate = self.labelManagingDelegate {

        }
        if let colorDelegate = self.colorManagingDelegate {

        }

        dayStartPoint = SCKDayPoint(hour: start, minute: 0, second: 0)
        dayEndPoint = SCKDayPoint(hour: end, minute: 0, second: 0)
        updateHourParameters()
        invalidateIntrinsicContentSize()
        invalidateLayoutForAllEventViews()
    }

    /// Makes the view update some of its parameters, such as the unavailable time
    /// ranges by reflecting the values supplied by the delegate.
    @objc public final func invalidateUserDefaults() {
        readDefaultsFromDelegate()
    }

    // MARK: - Unavailable time ranges

    /// The time ranges that should be drawn as unavailable in this view.
    private var unavailableTimeRanges: [SCKUnavailableTimeRange] = []

    /// Calculates the rect to be drawn as unavailable from a given unavailable time range.
    /// - Parameter rng: The unavailable time range.
    /// - Returns: The calcualted rect.
    func rectForUnavailableTimeRange(_ rng: SCKUnavailableTimeRange) -> CGRect {
        let canvas = contentRect
        let dayWidth: CGFloat = canvas.width / CGFloat(dayCount)
        let sDate = sharedCalendar.date(bySettingHour: rng.startHour, minute: rng.startMinute, second: 0,
                                        of: dateInterval.start)!
        let sOffset = calculateRelativeTimeLocation(for: sDate)
        if sOffset != SCKRelativeTimeLocationInvalid {
            let endSeconds = rng.endMinute * 60 + rng.endHour * 3600
            let startSeconds = rng.startMinute * 60 + rng.startHour * 3600
            let eDate = sDate.addingTimeInterval(Double(endSeconds - startSeconds))
            let yOrigin = yFor(hour: rng.startHour, minute: rng.startMinute)
            var yLength: CGFloat = frame.maxY - yOrigin // Assuming SCKRelativeTimeLocationInvalid for eDate
            if calculateRelativeTimeLocation(for: eDate) != SCKRelativeTimeLocationInvalid {
                yLength = yFor(hour: rng.endHour, minute: rng.endMinute) - yOrigin
            }
            let weekday = (rng.weekday == -1) ? 0.0 : CGFloat(rng.weekday)
            return CGRect(x: canvas.minX + weekday * dayWidth, y: yOrigin, width: dayWidth, height: yLength)
        }
        return .zero
    }

    // For any given date in the dateInterval, returns origin of an event scheduled at the interval
    public func getCanvasRectForEvent(_ event: SCKEvent) -> CGRect? {
        // Try to find the event view
        guard let foundIndex = self.subviews.index(where: { (($0 as? SCKEventView)!.eventHolder.representedObject == event) }) else {
            return nil
        }
        guard let eventView: SCKEventView = self.subviews[foundIndex] as? SCKEventView else {
            return nil
        }
        return eventView.frame
    }


    // For any given event object, returns the corresponding view if it exists.
    public func getEventViewForEvent(_ event: SCKEvent) -> SCKEventView? {
        // Try to find the event view
        guard let foundIndex = self.subviews.index(where: { (($0 as? SCKEventView)!.eventHolder.representedObject == event) }) else {
            return nil
        }
        guard let eventView: SCKEventView = self.subviews[foundIndex] as? SCKEventView else {
            return nil
        }
        return eventView
    }






    // For any given date in the dateInterval, returns origin of an event scheduled at the interval
    public func getCanvasPositionForDate(_ date: Date) -> CGPoint {
        let canvas = contentRect
        let dayWidth: CGFloat = canvas.width / CGFloat(dayCount)
        let offsetPerDay = 1.0/Double(dayCount)
        /// The relative start time of the event in the `scheduleView` date bounds.
        let relativeStart = self.calculateRelativeTimeLocation(for: date)
        let day = Int(trunc(relativeStart/offsetPerDay))
        let sPoint = SCKDayPoint(date: date)
        let eMinute = sPoint.minute
        let ePoint = SCKDayPoint(hour: sPoint.hour, minute: eMinute, second: sPoint.second)
        var newOrigin: CGPoint = CGPoint.zero
        newOrigin.y = yFor(hour: sPoint.hour, minute: sPoint.minute)
        newOrigin.x = canvas.minX + CGFloat(day) * dayWidth
        return newOrigin
    }






    // MARK: - Minute timer

    /// A timer that fires every minute to mark the view as needing display in order to update the "now" line.
    private lazy var minuteTimer: Timer = {
        let sel = #selector(SCKGridView.minuteTimerFired(timer:))
        let t = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: sel, userInfo: nil, repeats: true)
        t.tolerance = 50.0
        return t
    }()

    @objc dynamic func minuteTimerFired(timer: Timer) {
        needsDisplay = true
    }

    // MARK: - Drawing

    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard hourCount > 0 else { return }
        drawUnavailableTimeRanges()
        drawDayDelimiters()
        drawHourDelimiters()
        drawCurrentTimeLine()
        drawDraggingGuidesIfNeeded()
    }

    open func drawUnavailableTimeRanges() {
        self.unavailableTimeRangesColor.set()
        unavailableTimeRanges.forEach { rectForUnavailableTimeRange($0).fill() }
    }

    open func drawDayDelimiters() {
        let canvas = CGRect(x: Constants.HourAreaWidth, y: Constants.DayAreaHeight, width: frame.width-Constants.HourAreaWidth, height: frame.height-Constants.DayAreaHeight)
        let dayWidth = canvas.width / CGFloat(dayCount)
        self.dayDelimetersColor.set()
        //NSColor(deviceWhite: 0.95, alpha: 1.0).set()
        for day in 0..<dayCount {
            CGRect(x: canvas.minX + CGFloat(day) * dayWidth, y: canvas.minY, width: 1.0, height: canvas.height).fill()
        }
    }

    open func drawHourDelimiters() {
        self.hourDelimetersColor.set()
        for hour in 0..<hourCount {
            CGRect(x: contentRect.minX-8.0, y: contentRect.minY + CGFloat(hour) * hourHeight - 0.4,
                           width: contentRect.width + 8.0, height: 1.0).fill()
        }
    }

    open func drawCurrentTimeLine() {
        let canvas = contentRect
        let components = sharedCalendar.dateComponents([.hour, .minute], from: Date())
        let minuteCount = Double(hourCount) * 60.0
        let elapsedMinutes = Double(components.hour!-firstHour) * 60.0 + Double(components.minute!)
        let yOrigin = canvas.minY + canvas.height * CGFloat(elapsedMinutes / minuteCount)
        self.currentTimeLineColor.setFill()
        CGRect(x: canvas.minX, y: yOrigin-0.25, width: canvas.width, height: 0.5).fill()
        NSBezierPath(ovalIn: CGRect(x: canvas.minX-2.0, y: yOrigin-2.0, width: 4.0, height: 4.0)).fill()
    }


    open func drawDraggingGuidesIfNeeded() {
        guard let dV = eventViewBeingDragged else {return}
        (dV.backgroundColor ?? NSColor.darkGray).setFill()

        func fill(_ xPos: CGFloat, _ yPos: CGFloat, _ wDim: CGFloat, _ hDim: CGFloat) {
            CGRect(x: xPos, y: yPos, width: wDim, height: hDim).fill()
        }
        let canvas = contentRect
        let dragFrame = dV.frame

        // Left, right, top and bottom guides
        fill(canvas.minX, dragFrame.midY-1.0, dragFrame.minX-canvas.minX, 2.0)
        fill(dragFrame.maxX, dragFrame.midY-1.0, frame.width-dragFrame.maxX, 2.0)
        fill(dragFrame.midX-1.0, canvas.minY, 2.0, dragFrame.minY-canvas.minY)
        fill(dragFrame.midX-1.0, dragFrame.maxY, 2.0, frame.height-dragFrame.maxY)

        let dayWidth = canvas.width / CGFloat(dayCount)
        let offsetPerDay = 1.0/Double(dayCount)
        let startOffset = relativeTimeLocation(for: CGPoint(x: dragFrame.midX, y: dragFrame.minY))
        if startOffset != SCKRelativeTimeLocationInvalid {
            fill(canvas.minX+dayWidth*CGFloat(trunc(startOffset/offsetPerDay)), canvas.minY, dayWidth, 2.0)
            let startDate = calculateDate(for: startOffset)!
            let sPoint = SCKDayPoint(date: startDate)
            let ePoint = SCKDayPoint(date: startDate.addingTimeInterval(Double(dV.eventHolder.cachedDuration)*60.0))
            let sLabelText = NSString(format: "%ld:%02ld", sPoint.hour, sPoint.minute)
            let eLabelText = NSString(format: "%ld:%02ld", ePoint.hour, ePoint.minute)
            let attrs: [NSAttributedStringKey: Any] = [
                .foregroundColor: NSColor.darkGray,
                .font: NSFont.systemFont(ofSize: 12.0)
            ]
            let sLabelSize = sLabelText.size(withAttributes: attrs)
            let eLabelSize = eLabelText.size(withAttributes: attrs)
            let sLabelRect = CGRect(x: Constants.HourAreaWidth/2.0-sLabelSize.width/2.0,
                                    y: dragFrame.minY-sLabelSize.height/2.0,
                                    width: sLabelSize.width, height: sLabelSize.height)
            let eLabelRect = CGRect(x: Constants.HourAreaWidth/2.0-eLabelSize.width/2.0,
                                    y: dragFrame.maxY-eLabelSize.height/2.0,
                                    width: eLabelSize.width, height: eLabelSize.height)
            sLabelText.draw(in: sLabelRect, withAttributes: attrs)
            eLabelText.draw(in: eLabelRect, withAttributes: attrs)
            let durationText = "\(dV.eventHolder.cachedDuration) min"
            let dLabelSize = durationText.size(withAttributes: attrs)
            let durationRect = CGRect(x: Constants.HourAreaWidth/2.0-dLabelSize.width/2.0,
                                      y: dragFrame.midY-dLabelSize.height/2.0,
                                      width: dLabelSize.width, height: dLabelSize.height)
            durationText.draw(in: durationRect, withAttributes: attrs)
        }
    }
}

// MARK: - Hour height and zoom

extension SCKGridView {

    /// A prefix that appended to the class name works as a user defaults key for
    /// the last zoom level used by each subclass.
    private static let defaultsZoomKeyPrefix = "MEKZoom"

    /// Increases the hour height property if less than the maximum value. Marks the view as needing display.
    func increaseZoomFactor() {
        if hourHeight < Constants.MaxHeightPerHour {
            hourHeight += 8.0
            needsDisplay = true
        }
    }

    /// Decreases the hour height property if greater than the minimum value. Marks the view as needing display.
    func decreaseZoomFactor() {
        processNewHourHeight(hourHeight - 8.0)
    }

    open override func magnify(with event: NSEvent) {
        processNewHourHeight(hourHeight + 16.0 * event.magnification)
    }

    /// Increases or decreases the hour height property if greater than the minimum value and less than the maximum
    /// hour height. Marks the view as needing display.
    /// - Parameter targetHeight: The calculated new hour height.
    fileprivate func processNewHourHeight(_ targetHeight: CGFloat) {
        guard targetHeight < Constants.MaxHeightPerHour else {
            hourHeight = Constants.MaxHeightPerHour
            needsDisplay = true
            return
        }
        let minimumContentHeight = superview!.frame.height - Constants.paddingTop
        if targetHeight * CGFloat(hourCount) >= minimumContentHeight {
            hourHeight = targetHeight
        } else {
            hourHeight = minimumContentHeight / CGFloat(hourCount)
        }
        needsDisplay = true
    }
}

extension SCKGridView {

    open func zoomOut() {
        self.processNewHourHeight(-1000.0)
    }
}
