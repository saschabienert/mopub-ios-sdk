//
//  HZAnalytics.m
//  Heyzap
//
//  Created by Simon Maynard on 9/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HZAnalytics.h"
#import "HZUtils.h"
#import "HZLog.h"
#import "HZAPIClient.h"
#import "HeyzapAds.h"

#define ANALYTIC_URL @"/mobile/track_sdk_event"

#define kHeyzapStart @"heyzap_start"
#define kHeyzapStop  @"heyzap_stop"

static HZAnalytics *HZAnalyticsSharedInstance = nil;

@interface HZAnalytics()
@property (nonatomic, strong) NSMutableArray *outstandingAnalytics;
@property (nonatomic, strong) NSDictionary *analyticBeingTransmitted;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic) BOOL startSentThisSession;
@end

@implementation HZAnalytics

@synthesize outstandingAnalytics=_outstandingAnalytics;
@synthesize analyticBeingTransmitted=_analyticBeingTransmitted;
@synthesize data=_data;

#pragma mark Static Methods

+ (HZAnalytics*) sharedInstance {
    static dispatch_once_t _singletonPredicate;
    
    dispatch_once(&_singletonPredicate, ^{
        HZAnalyticsSharedInstance = [[super allocWithZone:nil] init];
        
        // Do a Heyzap Start.
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{ // this class isn't thread safe b/c of the mutable dictionary access.
                [HZAnalytics logAnalyticsEvent: kHeyzapStart];
            });
        });

    });
    
    return HZAnalyticsSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

+ (NSMutableDictionary *) defaultAnalyticsParamsForEvent: (NSString *)eventName {
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            [HZUtils urlEncodeString:[HZUtils deviceID] usingEncoding:NSUTF8StringEncoding], @"device_id",
            eventName, @"type",
            @"iphone", @"platform",
            SDK_VERSION, @"analytics_sdk_version",
            [UIDevice currentDevice].systemVersion, @"analytics_os_version",
            nil];
    
    if ([HZUtils appID] != nil) {
        [dict setObject: [HZUtils appID] forKey: @"analytics_for_game_store_id"];
    }
    
    return dict;
}

+ (void) logAnalyticsEvent: (NSString *) eventName withValuesFromDictionary: (NSDictionary *)dictionary {
    NSMutableDictionary *params = [HZAnalytics defaultAnalyticsParamsForEvent:eventName];
    [params addEntriesFromDictionary:dictionary];
    
    [HZAnalytics logAnalyticsEvent:eventName andParams:params];
}

+ (void) logAnalyticsEvent: (NSString *) eventName andValue: (NSString *)value forKey: (NSString *)key {
    NSMutableDictionary *params = [HZAnalytics defaultAnalyticsParamsForEvent:eventName];
    [params setObject:value forKey:key];
    
    [HZAnalytics logAnalyticsEvent:eventName andParams:params];
}

+ (void) logAnalyticsEvent: (NSString *) eventName {
    NSMutableDictionary *params = [HZAnalytics defaultAnalyticsParamsForEvent:eventName];
    
    [HZAnalytics logAnalyticsEvent:eventName andParams:params];
}

+ (void) logAnalyticsEvent: (NSString *) eventName andParams: (NSDictionary*)params {
    if ([HZUtils appID] == nil) {
        return;
    }

    [[[HZAnalytics sharedInstance] outstandingAnalytics] addObject:params];
    [[[HZAnalytics sharedInstance] outstandingAnalytics] writeToFile:[HZAnalytics generateAnalyticsFilename] atomically:YES];
    
    [[HZAnalytics sharedInstance] sendAnalytic:params];
}

+ (NSString*) generateAnalyticsFilename {
    return [HZUtils pathWithFilename: @"analytics.cache"];
}

#pragma mark Init functions

- (id)init {
    self = [super init];
    if (self) {
        
        self.startSentThisSession = false;
        
        // Start it up
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationEvent:)
                                                     name: UIApplicationDidBecomeActiveNotification object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationEvent:)
                                                     name: UIApplicationWillEnterForegroundNotification object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationEvent:)
                                                     name: UIApplicationDidEnterBackgroundNotification object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationEvent:)
                                                     name: UIApplicationWillResignActiveNotification object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationEvent:)
                                                     name: UIApplicationWillTerminateNotification object: nil];
        
        // Initialization code here.
        self.outstandingAnalytics = [NSMutableArray arrayWithContentsOfFile:[HZAnalytics generateAnalyticsFilename]];
        if ( self.outstandingAnalytics == nil ) {
            self.outstandingAnalytics = [[NSMutableArray alloc] init];
        }
        
        self.analyticBeingTransmitted = nil;
        if ([self.outstandingAnalytics count] > 0) {
            [HZAnalyticsSharedInstance sendAnalytic:[self.outstandingAnalytics objectAtIndex:0]];
        }
    }
    
    return self;
}

- (void) dealloc {
    // Unsubscribe from all events
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark Instance methods

- (void) sendAnalytic: (NSDictionary *) analytic {
    
    if ( HZAnalyticsSharedInstance.analyticBeingTransmitted == nil ) {
        HZAnalyticsSharedInstance.analyticBeingTransmitted = analytic;
        [[HZAPIClient sharedClient] post: ANALYTIC_URL  withParams: analytic success:^(id data) {
            
            [self.outstandingAnalytics removeObject:self.analyticBeingTransmitted];
            [self.outstandingAnalytics writeToFile:[HZAnalytics generateAnalyticsFilename] atomically:YES];
            self.analyticBeingTransmitted = nil;
            self.data = nil;
            if ([self.outstandingAnalytics count] > 0) {
                [HZAnalyticsSharedInstance sendAnalytic:[self.outstandingAnalytics objectAtIndex:0]];
            }
            
        } failure:^(NSError *error) {
            
            self.data = nil;
            self.analyticBeingTransmitted = nil;
            
        }];
    }
}

#pragma mark - Application Notifications

- (void) applicationEvent: (NSNotification *) notification {
    if ([[notification name] isEqualToString: UIApplicationDidBecomeActiveNotification]) {
        if (!self.startSentThisSession) {
            [HZAnalytics logAnalyticsEvent: kHeyzapStart];
        }
    }
    
    if ([[notification name] isEqualToString: UIApplicationDidEnterBackgroundNotification]) {
        [HZAnalytics logAnalyticsEvent: kHeyzapStop];
        self.startSentThisSession = false;
    }
    
    if ([[notification name] isEqualToString: UIApplicationWillEnterForegroundNotification]) {
        [HZAnalytics logAnalyticsEvent: kHeyzapStop];
        self.startSentThisSession = false;
    }
    
    if ([[notification name] isEqualToString: UIApplicationWillResignActiveNotification]) {
        // Do Nothing.
    }
    
    if ([[notification name] isEqualToString: UIApplicationWillTerminateNotification]) {
        [HZAnalytics logAnalyticsEvent: kHeyzapStop];
        self.startSentThisSession = false;
    }
 }


@end
