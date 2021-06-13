//
//  SCKLabelManaging.swift
//  ScheduleKit
//
//  Created by Pho Hale on 4/30/18.
//  Copyright © 2018 Guillem Servera. All rights reserved.
//

import Foundation
import Cocoa

// MARK: -
// MARK: - protocol SCKLabelManaging
// Description: Delegate for configuring displayed left sidebar time labels and header date labels

/* //// Responsibilities:
 - Format and configure labels that are added and removed programmatically by SCK
*/
/* //// Known Uses:
 - SCKGridView, SCKView
*/
public protocol SCKLabelManaging: class {
    var dayLabelsDateFormatter: DateFormatter {get}
    var monthLabelsDateFormatter: DateFormatter {get}

    func getLabel(forLabelType type: LabelType) -> NSTextField
    func getLabelColor(forLabelType type: LabelType) -> NSColor

    func label(_ text: String, size: CGFloat, color: NSColor) -> NSTextField

    // If true, disables the programmatic generation of day header labels so a custom layout can be performed.
    var shouldDisableDayHeaderLabels: Bool {get}

}

public extension SCKLabelManaging {

    var shouldDisableDayHeaderLabels: Bool { return false }

    var dayLabelsDateFormatter: DateFormatter {
        let f = DateFormatter();
        f.dateFormat = "EEEE d";
        return f
    }

    var monthLabelsDateFormatter: DateFormatter {
        let f = DateFormatter();
        f.dateFormat = "MMMM";
        return f
    }


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
        let labelSize: CGFloat = self.getLabelSize(forLabelType: type)
        let labelText: String = self.getLabelText(forLabelType: type)
        return label(labelText, size: labelSize, color: labelColor)
//        switch type {
//        case .month:
//            return label("", size: 12.0, color: labelColor)
//        case .day:
//            return label("", size: 14.0, color: labelColor)
//        case .hour(let hour):
//            return label("\(hour):00", size: 11, color: labelColor)
//        case .min(let hour, let min):
//            return label("\(hour):\(min)  -", size: 10, color: labelColor)
//        default:
//            fatalError()
//        }
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

    func getLabelText(forLabelType type: LabelType) -> String {
        switch type {
        case .month(let date):
            guard let validDate = date else { return "" }
            return self.monthLabelsDateFormatter.string(from: validDate)

        case .day(let date):
            guard let validDate = date else { return "" }
            return self.dayLabelsDateFormatter.string(from: validDate)

        case .hour(let hour):
            return "\(hour):00"

        case .min(let hour, let min):
            return "\(hour):\(min)  -"

        default:
            return "???"
        }
    }

    func getLabelSize(forLabelType type: LabelType) -> CGFloat {
        switch type {
        case .month(let date):
            return 12.0

        case .day(let date):
            return 14.0

        case .hour(let hour):
            return 11.0

        case .min(let hour, let min):
            return 10.0

        default:
            return 12.0
        }
    }


}
