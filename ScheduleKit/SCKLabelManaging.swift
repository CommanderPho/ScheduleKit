//
//  SCKLabelManaging.swift
//  ScheduleKit
//
//  Created by Pho Hale on 4/30/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation
import Cocoa


public enum LabelType { case month, day
    case hour(hourValue: Int)
    case min(hourValue: Int, minValue: Int)
    case other
}


public protocol SCKLabelManaging: class {
    func getLabel(forLabelType type: LabelType) -> NSTextField
    func getLabelColor(forLabelType type: LabelType) -> NSColor

    func label(_ text: String, size: CGFloat, color: NSColor) -> NSTextField

}

public extension SCKLabelManaging {

    func label(_ text: String, size: CGFloat, color: NSColor) -> NSTextField {
        let label = NSTextField(frame: .zero)
        label.isBordered = false; label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        label.stringValue = text
        label.font = .systemFont(ofSize: size)
        label.textColor = color
        label.sizeToFit() // Needed
        return label
    }

    func getLabel(forLabelType type: LabelType) -> NSTextField {
        let labelColor: NSColor = self.getLabelColor(forLabelType: type)
        switch type {
        case .month:
            return label("", size: 12.0, color: labelColor)
        case .day:
            return label("", size: 14.0, color: labelColor)
        case .hour(let hour):
            return label("\(hour):00", size: 11, color: labelColor)
        case .min(let hour, let min):
            return label("\(hour):\(min)  -", size: 10, color: labelColor)
        default:
            fatalError()
        }
    }

    func getLabelColor(forLabelType type: LabelType) -> NSColor {
        switch type {
        case .month:
            return NSColor.lightGray
        case .day:
            return NSColor.darkGray
        case .hour:
            return NSColor.darkGray
        case .min:
            return NSColor.lightGray
        default:
            return NSColor.red
        }
    }


}
