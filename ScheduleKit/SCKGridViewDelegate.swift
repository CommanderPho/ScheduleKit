/*
 *  SCKGridViewDelegate.swift
 *  ScheduleKit
 *
 *  Created:    Guillem Servera on 28/10/2016.
 *  Copyright:  © 2016-2017 Guillem Servera (https://github.com/gservera)
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

/// An object conforming to the `SCKGridViewDelegate` protocol may implement a
/// method to provide unavailable time ranges to a grid-style schedule view in
/// addition to other methods defined in `SCKViewDelegate`.
@objc public protocol SCKGridViewDelegate: SCKViewDelegate {

    /// Implement this method to specify the first displayed hour. Defaults to 0.
    ///
    /// - Parameter gridView: The grid view asking for a start hour.
    /// - Returns: An hour value from 0 to 24.
    @objc(dayStartHourForGridView:) func dayStartHour(for gridView: SCKGridView) -> Int

    /// Implement this method to specify the last displayed hour. Defaults to 24.
    ///
    /// - Parameter gridView: The grid view asking for a start hour.
    /// - Returns: An hour value from 0 to 24, where 0 is parsed as 24.
    @objc(dayEndHourForGridView:) func dayEndHour(for gridView: SCKGridView) -> Int

    /// Implemented by a grid-style schedule view's delegate to provide an array
    /// of unavailable time ranges that are drawn as so by the view.
    ///
    /// - Parameter gridView: The schedule view asking for the values.
    /// - Returns: The array of unavailable time ranges (may be empty).
    @objc(unavailableTimeRangesForGridView:)
    optional func unavailableTimeRanges(for gridView: SCKGridView) -> [SCKUnavailableTimeRange]
}
