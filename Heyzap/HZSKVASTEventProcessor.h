//
//  SKVASTEventProcessor.h
//  VAST
//
//  Created by Thomas Poland on 10/3/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//
//  VASTEventTracker wraps NSURLRequest to handle sending tracking and impressions events defined in the VAST 2.0 document and stored in VASTModel.

#import <Foundation/Foundation.h>
#import "HZSKVASTViewController.h"

typedef enum {
    VASTEventTrackStart,
    VASTEventTrackFirstQuartile,
    VASTEventTrackMidpoint,
    VASTEventTrackThirdQuartile,
    VASTEventTrackComplete,
    VASTEventTrackClose,
    VASTEventTrackPause,
    VASTEventTrackResume,
    VASTEventTrackSkip, //added for mdotm - sent when ad is skipped
    VASTEventTrackEngagedView //added for mdotm - sent when view lasts at least 30sec (or completes, if shorter than 30sec)
} HZSKVASTEvent;

@interface HZSKVASTEventProcessor : NSObject

- (id)initWithTrackingEvents:(NSDictionary *)trackingEvents withDelegate:(id<HZSKVASTViewControllerDelegate>)delegate;    // designated initializer, uses tracking events stored in VASTModel
- (void)trackEvent:(HZSKVASTEvent)vastEvent;                       // sends the given VASTEvent
- (void)sendVASTUrlsWithId:(NSArray *)vastUrls;                // sends the set of http requests to supplied URLs, used for Impressions, ClickTracking, and Errors.

@end
