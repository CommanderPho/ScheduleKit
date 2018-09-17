//
//  LabelType.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation

// MARK: -
// MARK: - enum LabelType
// Description: The configuration of a displayed label

/* //// Responsibilities:
 - Used by SCKLabelManaging delegates to update label display
 */
/* //// Known Uses:
 -
 */
public enum LabelType {
    case month(date: Date?)
    case day(date: Date?)
    case hour(hourValue: Int)
    case min(hourValue: Int, minValue: Int)
    case other
}
