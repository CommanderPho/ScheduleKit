//
//  SCKLayoutManaging.swift
//  ScheduleKit
//
//  Created by Pho Hale on 4/30/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation
import Cocoa


public protocol SCKLayoutManaging: class {
    var layoutConstants: SCKLayoutConstants { get }
}


public extension SCKLayoutManaging {

    var layoutConstants: SCKLayoutConstants {
        return SCKLayoutConstants(DayAreaHeight: 40.0, DayAreaMarginBottom: 20.0, MaxHeightPerHour: 300.0, HourAreaWidth: 56.0)
    }

}
