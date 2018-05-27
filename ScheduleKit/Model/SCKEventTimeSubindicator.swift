//
//  SCKEventTimeSubindicator.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Cocoa


public struct SCKEventTimeSubindicatorConfig {
    var thickness: CGFloat = 2.0

    var color: NSColor? = NSColor.white.withAlphaComponent(0.7)

    var height: CGFloat = 1.0
    // The offset within the event view. 0.0 is the top of the view and 1.0 is the bottom
    var eventViewRelativeOffset: CGFloat = 0.0

    //var shouldDisplay: Bool { return (self.eventViewRelativeOffset > 0.0) }

    init(eventViewRelativeOffset: CGFloat = 0.0) {
        self.eventViewRelativeOffset = 0.0
    }
}
