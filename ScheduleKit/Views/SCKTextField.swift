/*
 *  SCKTextField.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 3/10/2016.
 *  Copyright:  © 2014-2019 Guillem Servera (https://github.com/gservera)
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

import Foundation
import AppKit
import Cocoa

open class SCKTextFieldCell: NSTextFieldCell {

    /// A flag property to track whether the text field is selected or being
    /// edited.
    public var editingOrSelected = false

    open override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var rect = super.drawingRect(forBounds: rect)
        if !editingOrSelected {
            let size = cellSize(forBounds: rect)
            let deltaHeight = rect.height - size.height
            if deltaHeight > 0.0 {
                rect.size.height -= deltaHeight
                rect.origin.y = deltaHeight / 2.0
            }
        }
        return rect
    }

    override open func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        let newRect = drawingRect(forBounds: rect)
        editingOrSelected = true
        super.select(withFrame: newRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
        editingOrSelected = false
    }

    override open func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        let newRect = drawingRect(forBounds: rect)
        editingOrSelected = true
        super.edit(withFrame: newRect, in: controlView, editor: textObj, delegate: delegate, event: event)
        editingOrSelected = false
    }


}

/// This class provides a custom NSTextField whose cell renders its string value
/// vertically centered when the actual text is not selected and/or being edited.
open class SCKTextField: NSTextField {

    override open class var cellClass: AnyClass? {
        get {
            return SCKTextFieldCell.self
        }
        set {
            super.cellClass = newValue
        }
    }


    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUpDefaultProperties()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpDefaultProperties()
    }

    open override func contentCompressionResistancePriority(for orientation: NSLayoutConstraint.Orientation) -> NSLayoutConstraint.Priority {
        switch orientation {
        case .horizontal:
            return NSLayoutConstraint.Priority(rawValue: 249.0)
        default:
            return NSLayoutConstraint.Priority(rawValue: 249.0)
        }
    }


    public var isDebugMode: Bool = false {
        didSet {
            self.backgroundColor = NSColor.orange.withAlphaComponent(0.5)
            self.setUpDefaultProperties()
            self.setNeedsDisplay()
        }
    }

    open override func layoutSubtreeIfNeeded() {
        self.preferredMaxLayoutWidth = self.frame.size.width
        super.layoutSubtreeIfNeeded()
    }
    /// Sets up the text field default properties.
    open func setUpDefaultProperties() {
        self.drawsBackground = self.isDebugMode
        self.isEditable = false
        self.isBezeled = false
        self.alignment = .center
        self.font = .systemFont(ofSize: 12.0)
        self.setupCell()
        self.usesSingleLineMode = false
        self.lineBreakMode = .byWordWrapping
        self.allowsDefaultTighteningForTruncation = true
        self.maximumNumberOfLines = 2
//        self.preferredMaxLayoutWidth = self.bounds.width
    }


    open func setupCell() {
        guard let validCell = self.cell else { fatalError() }
        guard let customValidCell = validCell as? SCKTextFieldCell else { fatalError() }
        customValidCell.usesSingleLineMode = false
        customValidCell.wraps = true
        customValidCell.lineBreakMode = .byWordWrapping
        customValidCell.truncatesLastVisibleLine = false
    }


}
