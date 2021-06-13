//
//  SCKUser.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Cocoa

/// Any type implementing the relevant methods for an `SCKEvent`'s user.
@objc public protocol SCKUser: class {

    /// The color that will be used as `SCKEventView`s background when displayed
    /// in a `SCKView` with `colorMode` set to `.byEventOwner`.
    @objc var eventColor: NSColor { get }

    /// The color that will be used as `SCKEventView`s background when displayed
    /// in a `SCKView` with `colorMode` set to `.byEventOwner` and currently being reducedEmphasis because other events
    /// are selected and it isn't.
    @objc var reducedEmphasisEventColor: NSColor { get }


    /// The color that will be used as `SCKEventView`s label.textcolor when displayed
    /// in a `SCKView` with `colorMode` set to `.byEventOwner`
    @objc var eventOverlayColor: NSColor { get }

    /// The color that will be used as `SCKEventView`s label.textcolor when displayed
    /// in a `SCKView` with `colorMode` set to `.byEventOwner` and currently being reducedEmphasis because other events
    /// are selected and it isn't.
    @objc var reducedEmphasisEventOverlayColor: NSColor { get }
}

public func ==(lhs: SCKUser, rhs: SCKUser) -> Bool {
    if (lhs.eventColor != rhs.eventColor) { return false }
    return true
}
