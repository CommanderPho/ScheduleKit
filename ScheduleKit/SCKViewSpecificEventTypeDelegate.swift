//
//  SCKViewSpecificEventTypeDelegate.swift
//  ScheduleKit
//
//  Created by Pho Hale on 2/5/19.
//  Copyright © 2019 Guillem Servera. All rights reserved.
//

import Foundation
import Cocoa

/// An object conforming to the `SCKViewDelegate` protocol must implement a
/// method required to set a color schedule view events.
public protocol SCKViewSpecificEventTypeDelegate: SCKViewDelegate {

	/// Implemented by a schedule view's delegate to provide different background
	/// colors for the different event types when the view's color mode is set to
	/// `.bySpecificEvent`.
	///
	/// - Parameters:
	///   - eventValue: The event for which to return a color.
	///   - scheduleView: The schedule view asking for the color.
	/// - Returns: The color that will be used as the corresponding event view's
	///            background.
	func color(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor

	/// Implemented by a schedule view's delegate to provide different background
	/// colors for the different event types when the view's color mode is set to
	/// `.bySpecificEvent` and the event is event is de-emphaiszed, meaning greyed
	/// out from deselection
	///
	/// - Parameters:
	///   - eventValue: The event for which to return a color.
	///   - scheduleView: The schedule view asking for the color.
	/// - Returns: The color that will be used as the corresponding event view's
	///            background.
	func reducedEmphasisColor(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor

	func overlayColor(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor

	func reducedEmphasisOverlayColor(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor

}



//public extension SCKViewSpecificEventTypeDelegate {
//
//	// MARK: - SCKViewSpecificEventTypeDelegate default implementations
//	// We provide default implementations to make them optional
//
//	public func color(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor {
//		return NSColor.clear
//	}
//
//	public func reducedEmphasisColor(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor {
//		return NSColor.clear
//	}
//
//	public func overlayColor(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor {
//		return NSColor.clear
//	}
//
//	public func reducedEmphasisOverlayColor(for eventValue: SCKEvent, in scheduleView: SCKView) -> NSColor {
//		return NSColor.clear
//	}
//
//}
