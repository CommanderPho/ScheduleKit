//
//  SCKLayoutManaging.swift
//  ScheduleKit
//
//  Created by Pho Hale on 4/30/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation
import Cocoa



public struct SCKLayoutConstants {
    public var DayAreaHeight: CGFloat = 40.0
    public var DayAreaMarginBottom: CGFloat = 20.0
    public var MaxHeightPerHour: CGFloat = 300.0
    public var HourAreaWidth: CGFloat = 56.0
    public var paddingTop: CGFloat { return DayAreaHeight + DayAreaMarginBottom }

    public init(DayAreaHeight: CGFloat, DayAreaMarginBottom: CGFloat, MaxHeightPerHour: CGFloat, HourAreaWidth: CGFloat) {
        self.DayAreaHeight = DayAreaHeight
        self.DayAreaMarginBottom = DayAreaMarginBottom
        self.MaxHeightPerHour = MaxHeightPerHour
        self.HourAreaWidth = HourAreaWidth
    }

}


public protocol SCKLayoutManaging: class {
    var layoutConstants: SCKLayoutConstants { get }
}


public extension SCKLayoutManaging {

    var layoutConstants: SCKLayoutConstants {
        return SCKLayoutConstants(DayAreaHeight: 40.0, DayAreaMarginBottom: 20.0, MaxHeightPerHour: 300.0, HourAreaWidth: 56.0)
    }

}
