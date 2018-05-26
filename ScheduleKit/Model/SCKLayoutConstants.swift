//
//  SCKLayoutConstants.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation

public struct SCKLayoutConstants {
    public var DayAreaHeight: CGFloat = 40.0
    public var DayAreaMarginBottom: CGFloat = 20.0

    public var MaxHeightPerHour: CGFloat = 300.0

    public var HourAreaWidth: CGFloat = 56.0

    public var paddingTop: CGFloat { return DayAreaHeight + DayAreaMarginBottom }
    public var paddingBottom: CGFloat = 40.0
    public var paddingLeft: CGFloat { return HourAreaWidth }
    public var paddingRight: CGFloat = 0.0

    // Returns the content rect
    public func getRect(frame: CGRect) -> CGRect {
        let width: CGFloat = frame.width - (self.paddingLeft + self.paddingRight)
        let height: CGFloat = frame.height - (self.paddingTop + self.paddingBottom)
        return CGRect(x: self.paddingLeft, y: self.paddingTop, width: width, height: height)
    }

    // Returns the top rect that contains the day/month labels
    public func getDayHeaderRect(frame: CGRect) -> CGRect {
        let width: CGFloat = frame.width - (self.paddingLeft + self.paddingRight)
        let height: CGFloat = self.paddingTop
        return CGRect(x: self.paddingLeft, y: 0.0, width: width, height: height)
    }

    // Returns the left side that contains the hour/minute labels rect
    public func getLeftHoursHeaderRect(frame: CGRect) -> CGRect {
        let width: CGFloat = self.paddingLeft
        let height: CGFloat = frame.height
        return CGRect(x: 0.0, y: 0.0, width: width, height: height)
    }

    public init(DayAreaHeight: CGFloat, DayAreaMarginBottom: CGFloat, MaxHeightPerHour: CGFloat, HourAreaWidth: CGFloat, paddingBottom: CGFloat = 40.0, paddingRight: CGFloat = 0.0) {
        self.DayAreaHeight = DayAreaHeight
        self.DayAreaMarginBottom = DayAreaMarginBottom
        self.MaxHeightPerHour = MaxHeightPerHour
        self.HourAreaWidth = HourAreaWidth
        self.paddingBottom = paddingBottom
        self.paddingRight = paddingRight
    }

}
