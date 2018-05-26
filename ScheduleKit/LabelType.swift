//
//  LabelType.swift
//  ScheduleKit
//
//  Created by Pho Hale on 5/25/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation

public enum LabelType { case month(date: Date?), day(date: Date?)
    case hour(hourValue: Int)
    case min(hourValue: Int, minValue: Int)
    case other
}
