//
//  HZMetrics.m
//  Heyzap
//
//  Created by Noah Goetz on 7/22/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMetrics.h"
#import "HZUtils.h"
#import "HZLog.h"
#import "HZAPIClient.h"
#import "HeyzapAds.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "HZDevice.h"
#import "HZMetricsKey.h"



// Metrics
NSString *const kIsAvailableCalledKey = @"is_available_called";
NSString *const kFetchKey = @"fetched";
NSString *const kFetchFailedKey = @"fetch_failed";
NSString *const kFetchFailReasonKey = @"reason_fetch_failed";
NSString *const kShowAdResultKey = @"show_ad_status";
NSString *const kIsAvailablePercentDownloadedKey = @"is_available_percentage_downloaded";
NSString *const kIsAvailableTimeSincePreviousFetchKey = @"is_available_time_since_previous_relevant_fetch";
NSString *const kShowAdTimeSincePreviousRelevantFetchKey = @"show_ad_time_since_previous_relevant_fetch";

NSString *const kAdFailedToLoadValue = @"failed-on-load";

NSString * const kSendMetricsUrl = @"/in_game_api/metrics/export";

@interface HZMetrics()
@property (nonatomic, strong) NSMutableDictionary *metricsDict;
@property (nonatomic) CFTimeInterval fetchCalledTime;
@property (nonatomic) CFTimeInterval showAdCalledTime;
@property (nonatomic) CFTimeInterval startTime;
@end

NSString * metricFailureReason(NSDictionary *metric);

@implementation HZMetrics

// ****************************
// ***** Metric Lifecycle *****
// ****************************

// App startup -> Send all metrics from filesystem. Delete those metrics.

// Fetch ad -> Record metric info
// Download video -> Record metric info
// (etc)

// Ad showed -> Cache metric to disk. We're done with it at this point.

// App enters background -> Write all remaining metrics to disk.

// ****************************
// ****** Debugging Tips ******
// ****************************

// You can access the simulator file system at /Users/Max/Library/Application Support/iPhone Simulator/SIMULATOR_VERSION/Applications/APP_HASH/

#pragma mark Static Methods

+ (HZMetrics *) sharedInstance {
    static dispatch_once_t _singletonPredicate;
    static HZMetrics *HZMetricsSharedInstance = nil;
    dispatch_once(&_singletonPredicate, ^{
        HZMetricsSharedInstance = [[HZMetrics alloc] init];
    });
    
    return HZMetricsSharedInstance;
}

- (HZMetrics *) init {
    self = [super init];
    if (self) {
        NSLog(@"Initializing");
        _metricsDict = [[NSMutableDictionary alloc] init];

        _startTime = CACurrentMediaTime();
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(cacheAllMetrics)
                                                     name: UIApplicationDidEnterBackgroundNotification object: nil];
    }
    NSLog(@"making directory");
    [[self class] createMetricsDirectory];
    
    // Immad is worried that we'll send too many network requests
    [self performSelector:@selector(sendCachedMetrics) withObject:nil afterDelay:15];
    // Run NStimer to sweep up stuff?
    // Or send as soon as we get a 'show ad' and only cache to disk if it fails...?
    
    return self;
}

NSString * const kMetricID = @"metricIdentifier";
NSString * const kMetricDownloadPercentageKey = @"kCurrentDownloadPercentage";

+ (NSDictionary *)baseMetricsForAdType:(NSString *)adType
{
    return @{
             @"ad-unit": adType,
             kMetricID:[[self class] uniqueIdentifier],
            };
}

- (NSMutableDictionary *)getMetricsForTag:(NSString *)tag type:(NSString *)type {
    if (tag == nil ) tag = @"default";
    NSParameterAssert(type);
    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:tag type:type];
    if (!self.metricsDict[key]) {
        self.metricsDict[key] = [[[self class] baseMetricsForAdType:type] mutableCopy];
    }
    return self.metricsDict[key];
}

- (void)finishUsingAdWithTag:(NSString *)tag type:(NSString *)type {
    if (tag == nil ) tag = @"default";
    NSParameterAssert(type);
    
    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:tag type:type];
    NSDictionary *const metrics = self.metricsDict[key];
    [[self class] writeMetricToDisk:metrics];
    [self.metricsDict removeObjectForKey:key];
    
}

- (void) removeAdForTag:(NSString *)tag type:(NSString *)type {
    [self finishUsingAdWithTag:tag type:type];
//    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:tag type:type];
//    [self.metricsDict removeObjectForKey:key];
}

#pragma mark - Logging Metrics

- (void) logMetricsEvent: (NSString *) eventName value:(id)value tag:(NSString *)tag type:(NSString *)type {
    NSMutableDictionary *d = [self getMetricsForTag:tag type:type];
    d[eventName] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HZMetricsCached"
                                                        object:nil
                                                      userInfo:nil];
}

- (void) logFetchTimeForTag: (NSString *) tag type:(NSString *) type {
    self.fetchCalledTime = CACurrentMediaTime();
    [self logMetricsEvent:@"fetch" value:@1 tag:tag type:type];
}

- (void) logTimeSinceFetchFor:(NSString *)eventName tag:(NSString *)tag type:(NSString *)type{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceFetchMiliseconds = lround((currentTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:eventName value:@(elapsedtimeSinceFetchMiliseconds) tag:tag type:type];
}

- (void) logShowAdForTag:(NSString *)tag type:(NSString *)type{
    [[HZMetrics sharedInstance] logMetricsEvent:@"show_ad_called" value:@1 tag:tag type:type];
    self.showAdCalledTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((self.showAdCalledTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:kShowAdTimeSincePreviousRelevantFetchKey value:@(elapsedtimeSinceShowMiliseconds) tag:tag type:type];
}

- (void) logTimeSinceShowAdFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.showAdCalledTime)*1000);
    [self logMetricsEvent:eventname value:@(elapsedtimeSinceShowMiliseconds) tag:tag type:type];
}

- (void) logDownloadPercentageFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type{
    NSNumber *downloadPercentage = [self getMetricsForTag:tag type:type][kMetricDownloadPercentageKey];
    if (downloadPercentage) { // If we aren't downloading a video, don't log anything
        [self logMetricsEvent:eventname value:downloadPercentage tag:tag type:type];
    }
}

- (void) logTimeSinceStartFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type {
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.startTime)*1000);
    [self logMetricsEvent:eventname value:@(elapsedtimeSinceShowMiliseconds) tag:tag type:type];
}

- (void)logIsAvailable:(BOOL)isAvailable tag:(NSString *)tag type:(NSString *)type {
    if (tag == nil ) tag = @"default";
    NSParameterAssert(type);
    
    
    if (isAvailable) {
        [[HZMetrics sharedInstance] logMetricsEvent:@"is_available_result" value:@"is_available" tag:tag type:type];
    } else {
        NSDictionary *const currentMetric = [self getMetricsForTag:tag type:type];
        [self logMetricsEvent:@"is_available_status" value:metricFailureReason(currentMetric) tag:tag type:type];
    }
}

// This isn't actually a metric, but the metric dictionary is a useful place to store the current download percentage for that video ad.
- (void)setDownloadPercentage:(int)downloadPercentage tag:(NSString *)tag type:(NSString *)type {
    [self logMetricsEvent:kMetricDownloadPercentageKey value:@(downloadPercentage) tag:tag type:type];
}

+ (NSDictionary *) staticValuesDict {
    return @{
      @"carrier": [[CTTelephonyNetworkInfo alloc] init].subscriberCellularProvider.carrierName ?: @"",
      };
}

NSString *const kMetricsDir = @"hzMetrics";

- (NSArray *)getCachedMetrics {
    
    NSError *error;
    NSArray *const fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[[self class] metricsDirectory]
                                  includingPropertiesForKeys:nil
                                                     options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants|NSDirectoryEnumerationSkipsHiddenFiles)
                                                       error:&error];
    
    
    NSArray *const metricDictionaries = ({
        NSMutableArray *metrics = [[NSMutableArray alloc] init];
        for (NSURL *url in fileURLs) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
            if (dict) {
                [metrics addObject:dict];
            }
        }
        metrics;
    });
    return metricDictionaries;
}


- (void)sendCachedMetrics {
    NSLog(@"Sending cached metrics");
    NSArray *metrics = [self getCachedMetrics];
    NSArray *metricIDs = hzMap(metrics, ^NSURL *(NSDictionary *metric) {
        return metric[kMetricID];
    });
    
    if ([metrics count]) {
        
        NSMutableDictionary *params = [[[self class] staticValuesDict] mutableCopy];
        
        params[@"metrics"] = metrics;
        
        [[HZAPIClient sharedClient] post:kSendMetricsUrl withParams:params success:^(id data) {
            NSLog(@"Metrics sent = %lu",(unsigned long)[metrics count]);
            NSLog(@"Success! Response from server = %@",data);
            [[self class] clearMetricsWithMetricIDs:metricIDs];
        } failure:^(NSError *error) {
            NSLog(@"Error from server = %@",error);
        }];
    } else {
        NSLog(@"No metrics");
    }
}

#pragma mark - Cleanup

/**
 *  This method is called when the app enters the background (e.g. user presses home button).
 *  At this point we cache all the metrics to disk; if they re-enter the app we can just overwrite the files later.
 *  `applicationWillTerminate` is not reliably called so this approach is ideal.
 */
- (void)cacheAllMetrics
{
    NSLog(@"Cache all metrics called");
    [self.metricsDict enumerateKeysAndObjectsUsingBlock:^(HZMetricsKey *key, NSMutableDictionary *metric, BOOL *stop) {
        NSLog(@"About to write metric to disk");
        const BOOL success = [[self class] writeMetricToDisk:metric];
        NSLog(@"Wrote to disk = %i",success);
    }];
}

+ (void)clearMetricsWithMetricIDs:(NSArray *)metricIDs
{
    for (NSString *metridID in metricIDs) {
        NSURL *metricPath = [self pathToMetricWithID:metridID];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:metricPath error:&error];
    }
}

#pragma mark - Directory/File Utils

+ (void)createMetricsDirectory {
    NSURL *metricsPath = [self metricsDirectory];
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtURL:metricsPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"Error creating directory; error = %@",error);
    }
    
}

+ (BOOL)writeMetricToDisk:(NSDictionary *)metricDict {
    NSString *metricID = metricDict[kMetricID];
    NSURL *metricPath = [self pathToMetricWithID:metricID];
    return [metricDict writeToURL:metricPath atomically:YES];
}

+ (NSURL *)pathToMetricWithID:(NSString *)metricID {
    NSString *fileName = [self metricFileNameForID:metricID];
    return [[self metricsDirectory] URLByAppendingPathComponent:fileName];
}


+ (NSString *)metricFileNameForID:(NSString *)metricID {
    return [[@"hzMetric-" stringByAppendingString:metricID] stringByAppendingPathExtension:@"plist"];
}

+ (NSURL *)metricsDirectory {
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    
    NSError *directoryError;
    NSURL *directoryURL = [[NSURL fileURLWithPath:libraryDir] URLByAppendingPathComponent:@"hzMetrics" isDirectory:YES];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL
                             withIntermediateDirectories:YES
                                              attributes:@{}
                                                   error:&directoryError];
    
    return directoryURL;
}

#pragma mark - Utils

+ (NSString *)uniqueIdentifier
{
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

NSString * metricFailureReason(NSDictionary *metric) {
    if (metric[kFetchFailedKey]) {
        return @"not-available-fetch-failed";
    } else if (metric[kFetchKey]) {
        return @"not-available-fetch-downloading";
    } else {
        return @"not-available-not-fetching";
    }
}

#pragma mark - dealloc

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
