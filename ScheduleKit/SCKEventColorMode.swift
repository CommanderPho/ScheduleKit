//
//  SCKEventColorMode.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation

/// Possible color styles for drawing event view backgrounds.
@objc public enum SCKEventColorMode: Int {

    /// Colors events according to their event kind.
    case byEventKind

    /// Colors events according to their user's event color.
    case byEventOwner

	/// Colors events according to event-specific properties specified by the specificDelegate
	case bySpecificEvent
}
