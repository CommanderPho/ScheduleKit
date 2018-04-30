//
//  SCKColorManaging.swift
//  ScheduleKit
//
//  Created by Pho Hale on 4/29/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation
import Cocoa


public protocol SCKColorManaging: class {
    var backgroundColor: NSColor {get}
    var unavailableTimeRangesColor: NSColor {get}
    var dayDelimetersColor: NSColor {get}
    var hourDelimetersColor: NSColor {get}
    var currentTimeLineColor: NSColor {get}

}


public extension SCKColorManaging {
    var backgroundColor: NSColor { return NSColor.darkGray }
    var unavailableTimeRangesColor: NSColor { return NSColor(red: 0.925, green: 0.942, blue: 0.953, alpha: 1.0) }
    var dayDelimetersColor: NSColor { return NSColor(deviceWhite: 0.95, alpha: 1.0) }
    var hourDelimetersColor: NSColor { return NSColor(deviceWhite: 0.95, alpha: 1.0) }
    var currentTimeLineColor: NSColor { return NSColor.red }
}







