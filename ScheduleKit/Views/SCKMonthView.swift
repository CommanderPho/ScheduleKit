//
//  SCKMonthView.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Cocoa

/// An grid-style schedule view that displays events in a month date interval.
/// Use it by creating a new `SCKViewController` object and setting its `mode`
/// property to `SCKViewControllerMode.month`. Then, configure the view with
/// a date interval from the start of the first day in the month (00:00:00) to the
/// last second (23:59:59) of the last day.
///
/// Optionally, you may set the `delegate` property and implement its methods to
/// change the displayed hour range (which defaults to the whole day).
///
@objcMembers public final class SCKMonthView: SCKGridView {

    // MARK: - Displayed month offset

    /// Displays the previous month and asks the controller to fetch any matching
    /// events.
    func decreaseMonthOffset(_ sender: Any) {
        let c = sharedCalendar
        dateInterval = c.dateInterval(dateInterval, offsetBy: -1, .month)
        controller.internalReloadData()
    }

    /// Displays the next month and asks the controller to fetch any matching
    /// events.
    func increaseMonthOffset(_ sender: Any) {
        let c = sharedCalendar
        dateInterval = c.dateInterval(dateInterval, offsetBy: 1, .month)
        controller.internalReloadData()
    }

    /// Displays the default date interval (this month) and asks the controller to
    /// reload matching events.
    func resetMonthOffset(_ sender: Any) {
        let units: Set<Calendar.Component> = [.month]
        let monthComponents = sharedCalendar.dateComponents(units, from: Date())
        guard let start = sharedCalendar.date(from: monthComponents) else {
            fatalError("Could not calculate the start date for current month.")
        }
        dateInterval = DateInterval(start: start, duration: dateInterval.duration)
        controller.internalReloadData()
    }
}
