//
//  SCKEventManager.h
//  ScheduleKit
//
//  Created by Guillem on 28/12/14.
//  Copyright (c) 2014 Guillem Servera. All rights reserved.
//

#import "SCKEvent.h"
#import "SCKEventRequest.h"

@class SCKEventManager, SCKEventHolder, SCKView;

@protocol SCKEventManagerDataSource <NSObject>

- (NSArray *)eventManager:(SCKEventManager *)eM
requestsEventsBetweenDate:(NSDate*)sD
                  andDate:(NSDate*)eD;
- (void)eventManager:(SCKEventManager *)eM didMakeEventRequest:(SCKEventRequest*)request;

@end

@protocol SCKEventManagerDelegate <NSObject>
@optional

- (void)eventManager:(SCKEventManager*)eM didSelectEvent:(id <SCKEvent>)e;

- (void)eventManagerDidClearSelection:(SCKEventManager*)eM;
- (void)eventManager:(SCKEventManager *)eM didDoubleClickEvent:(id <SCKEvent>)e;
- (void)eventManager:(SCKEventManager *)eM didDoubleClickBlankDate:(NSDate*)d;

- (BOOL)eventManager:(SCKEventManager *)eM
shouldChangeLengthOfEvent:(id <SCKEvent>)e
           fromValue:(NSInteger)oV
             toValue:(NSInteger)fV;

- (BOOL)eventManager:(SCKEventManager *)eM
shouldChangeDateOfEvent:(id <SCKEvent>)e
           fromValue:(NSDate*)oD
             toValue:(NSDate*)fD;

@end

@interface SCKEventManager : NSObject {
    NSMutableArray * _managedContainers;
    NSPointerArray * _lastRequest;
    NSMutableArray * _asynchronousEventRequests;
}

- (NSInteger)positionInConflictForEventHolder:(SCKEventHolder*)e
                            holdersInConflict:(NSArray**)conflictsPtr;

- (void)reloadData;

@property (nonatomic, assign) BOOL loadsEventsAsynchronously;
@property (weak) id <SCKEventManagerDataSource> dataSource;
@property (weak) id <SCKEventManagerDelegate> delegate;
@property (weak) SCKView * view;
@end
