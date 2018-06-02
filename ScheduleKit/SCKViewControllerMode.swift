//
//  SCKViewControllerMode.swift
//  ScheduleKit
//
//  Created by Pho Hale on 6/1/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation

/// The date interval mode for a SCKViewController.
@objc public enum SCKViewControllerMode: Int {
    /// The controller works with a single day date interval.
    case day
    /// The controller works with a week date interval.
    case week
    /// The controller works with a month date interval.
    case month

    var defaultInterval: DateInterval {
        let calendar = Calendar.autoupdatingCurrent
        switch self {
        case .day:
            // Day
            let dayBeginning = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
            let dayEnding = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
            return DateInterval(start: dayBeginning, end: dayEnding)
        case .week:
            // Week
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            let weekEnding = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            return DateInterval(start: weekStart, end: weekEnding)
        case .month:
            // Month
            //            let monthStart = calendar.date(from: calendar.dateComponents([.month], from: Date()))!
            let monthStart = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: calendar.startOfDay(for: Date())))!
            let monthEnding = calendar.date(byAdding: .second, value: -1, to: calendar.date(byAdding: .month, value: 1, to: monthStart)!)
            return DateInterval(start: monthStart, end: monthEnding!)
        }
    }
}
