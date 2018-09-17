/*
 *  SCKViewDelegate.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 24/12/2014.
 *  Copyright:  © 2014-2017 Guillem Servera (https://github.com/gservera)
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

import Cocoa

/// An object conforming to the `SCKViewDelegate` protocol must implement a
/// method required to set a color schedule view events.
@objc public protocol SCKViewDelegate {

    /// Implemented by a schedule view's delegate to provide different background
    /// colors for the different event types when the view's color mode is set to
    /// `.byEventKind`.
    ///
    /// - Parameters:
    ///   - eventKindValue: The event kind for which to return a color.
    ///   - scheduleView: The schedule view asking for the color.
    /// - Returns: The color that will be used as the corresponding event view's
    ///            background.
    @objc (colorForEventKind:inScheduleView:)
    optional func color(for eventKindValue: Int, in scheduleView: SCKView) -> NSColor

    /// Implemented by a schedule view's delegate to provide different background
    /// colors for the different event types when the view's color mode is set to
    /// `.byEventKind` and the event is event is de-emphaiszed, meaning greyed
    /// out from deselection
    ///
    /// - Parameters:
    ///   - eventKindValue: The event kind for which to return a color.
    ///   - scheduleView: The schedule view asking for the color.
    /// - Returns: The color that will be used as the corresponding event view's
    ///            background.
    @objc (reducedEmphasisColorForEventKind:inScheduleView:)
    optional func reducedEmphasisColor(for eventKindValue: Int, in scheduleView: SCKView) -> NSColor

    @objc (overlayColorForEventKind:inScheduleView:)
    optional func overlayColor(for eventKindValue: Int, in scheduleView: SCKView) -> NSColor

    @objc (reducedEmphasisOverlayColorForEventKind:inScheduleView:)
    optional func reducedEmphasisOverlayColor(for eventKindValue: Int, in scheduleView: SCKView) -> NSColor


}
