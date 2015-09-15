//
//  SKVASTEventProcessor.m
//  VAST
//
//  Created by Thomas Poland on 10/3/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "HZSKVASTEventProcessor.h"
#import "HZSKVASTUrlWithId.h"
#import "HZSKLogger.h"

@interface HZSKVASTEventProcessor()

@property(nonatomic, strong) NSDictionary *trackingEvents;
@property(nonatomic, strong) id<HZSKVASTViewControllerDelegate> delegate;

@end


@implementation HZSKVASTEventProcessor

// designated initializer
- (id)initWithTrackingEvents:(NSDictionary *)trackingEvents withDelegate:(id<HZSKVASTViewControllerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.trackingEvents = trackingEvents;
        self.delegate = delegate;
    }
    return self;
}

- (void)trackEvent:(HZSKVASTEvent)vastEvent
{
    switch (vastEvent) {
     
        case VASTEventTrackStart:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"start"];
            }

            for (NSURL *aURL in (self.trackingEvents)[@"start"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent track start to url: %@", [aURL absoluteString]]];
            }
         break;
            
        case VASTEventTrackFirstQuartile:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"firstQuartile"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"firstQuartile"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent firstQuartile to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackMidpoint:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"midpoint"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"midpoint"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent midpoint to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackThirdQuartile:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"thirdQuartile"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"thirdQuartile"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent thirdQuartile to url: %@", [aURL absoluteString]]];
            }
            break;
 
        case VASTEventTrackComplete:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"complete"];
            }
            
            for( NSURL *aURL in (self.trackingEvents)[@"complete"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent complete to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackClose:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"close"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"close"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent close to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackPause:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"pause"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"pause"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent pause to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackResume:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"resume"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"resume"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent resume to url: %@", [aURL absoluteString]]];
            }
            break;
            
        case VASTEventTrackEngagedView:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"engagedView"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"engagedView"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent engagedView to url: %@", [aURL absoluteString]]];
            }

            break;
            
        case VASTEventTrackSkip:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"skip"];
            }
            
            for (NSURL *aURL in (self.trackingEvents)[@"skip"]) {
                [self sendTrackingRequest:aURL];
                [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent skip to url: %@", [aURL absoluteString]]];
            }
            
            break;
            
        default:
            if ([self.delegate respondsToSelector:@selector(vastTrackingEvent:)]) {
                [self.delegate vastTrackingEvent:@"Unknown"];
            }

            break;
    }
}

- (void)sendVASTUrlsWithId:(NSArray *)vastUrls
{
    for (HZSKVASTUrlWithId *urlWithId in vastUrls) {
        [self sendTrackingRequest:urlWithId.url];
        if (urlWithId.id_) {
            [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent http request %@ to url: %@", urlWithId.id_, urlWithId.url]];
        } else {
            [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Sent http request to url: %@", urlWithId.url]];
        }
    }
}

- (void)sendTrackingRequest:(NSURL *)trackingURL
{
    dispatch_queue_t sendTrackRequestQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(sendTrackRequestQueue, ^{
        NSURLRequest* trackingURLrequest = [ NSURLRequest requestWithURL:trackingURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:1.0];
        NSOperationQueue *senderQueue = [[NSOperationQueue alloc] init];
        [HZSKLogger debug:@"VAST - Event Processor" withMessage:[NSString stringWithFormat:@"Event processor sending request to url: %@", [trackingURL absoluteString]]];
        [NSURLConnection sendAsynchronousRequest:trackingURLrequest queue:senderQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError * connectionError) {
            
        }];  // Send the request only, no response or errors
    });
}

@end
