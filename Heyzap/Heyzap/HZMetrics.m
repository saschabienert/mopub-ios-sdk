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
#import "HZAdsManager.h"
#import "HZDispatch.h"



// Metrics
NSString *const kIsAvailableStatusKey = @"is_available_status";
NSString *const kIsAvailableCalledKey = @"is_available_called";
NSString *const kFetchKey = @"fetched";
NSString *const kFetchFailedKey = @"fetch_failed";
NSString *const kFetchFailReasonKey = @"reason_fetch_failed";
NSString *const kShowAdResultKey = @"show_ad_status";
NSString *const kIsAvailablePercentDownloadedKey = @"is_available_percentage_downloaded";
NSString *const kIsAvailableTimeSincePreviousFetchKey = @"is_available_time_since_previous_relevant_fetch";
NSString *const kShowAdTimeSincePreviousRelevantFetchKey = @"show_ad_time_since_previous_relevant_fetch";
NSString *const kNetworkKey = @"network";
NSString *const kNetworkVersionKey = @"network_version";
NSString *const kOrdinalKey = @"ordinal";
NSString *const kAdUnitKey = @"ad_unit";
NSString *const kConnectivityKey = @"connectivity";
NSString *const kFetchDownloadTimeKey = @"fetch_download_time";
NSString *const kTimeFromStartToShowAdKey = @"time_from_start_to_show_ad";
NSString *const kShowAdTimeTillAdIsDisplayedKey = @"show_ad_time_till_ad_is_displayed";
NSString *const kShowAdPercentageDownloadedKey = @"show_ad_percentage_downloaded";
NSString *const kAdClickedKey = @"ad_clicked";
NSString *const kCloseClickedKey = @"close_clicked";
NSString *const kTimeClickedKey = @"time_clicked";
NSString *const kNthAdKey = @"nth_ad";
NSString *const kTimeFromFetchToImpressionKey = @"time_from_fetch_to_impression";
NSString *const kVideoSizeKey = @"video_size";
NSString *const kVideoHostKey = @"video_host";
NSString *const kVideoPathKey = @"video_path";
NSString *const kVideoDownloadTimeKey = @"video_download_time";
NSString *const kVideoNotDownloadedButInterstitialShownValue = @"video-not-downloaded-but-interstitial-shown";
NSString *const kFullyCachedValue = @"fully-cached";
NSString *const kNoConnectivityValue = @"no-connectivity";
NSString *const kNoAdAvailableValue = @"no-ad-available";
NSString *const kAdAlreadyDisplayedValue = @"ad-already-displayed";
NSString *const kNotCachedAndNotAFetchableAdUnitValue = @"not-cached-and-not-a-fetchable-ad-unit";
NSString *const kNotCachedAndAttemptedFetchFailedValue = @"not-cached-and-attempted-fetch-failed";
NSString *const kNotCachedAndAttemptedFetchSuccessValue = @"not-cached-and-attempted-fetch-success";

NSString *const kAdFailedToLoadValue = @"failed-on-load";

NSString * const kSendMetricsUrl = @"/in_game_api/metrics/export";

@interface HZMetrics()
@property (nonatomic, strong) NSMutableDictionary *metricsDict;
@property (nonatomic, strong) NSMutableDictionary *preMediateMetricsDict;
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

// You can access the simulator file system at ~/Library/Application Support/iPhone Simulator/SIMULATOR_VERSION/Applications/APP_HASH/

// ****************************
// *** Refactoring Thoughts ***
// ****************************

// This Metrics system is based on Noah's original implementation, and of course this release was rushed, so I'm not 100% happy with it.

// Instead of storing metrics in an NSMutableDictionary, store them in object with tons of properties like Android does.
// This would make things more typesafe, though we'd have to write a bunch of annoying serialization code for it.
// Another advantage is that we could return that object to set properties on it, which is nice when we're doing several metrics at once.


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
        _metricsDict = [[NSMutableDictionary alloc] init];
        _preMediateMetricsDict = [[NSMutableDictionary alloc] init];

        _startTime = CACurrentMediaTime();
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cacheAllMetrics)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    [[self class] createMetricsDirectory];
    
    // Check to see if we need to send metrics every 15 seconds.
    // This avoids sending many HTTP requests at app launch, when we're already busy fetching (Immad's concern).
    // It also cleanly handles us having potentially alot of metrics.
    [NSTimer scheduledTimerWithTimeInterval:15
                                     target:self
                                   selector:@selector(sendCachedMetrics)
                                   userInfo:nil
                                    repeats:YES];
    
    return self;
}

NSString * const kMetricID = @"metricIdentifier";
NSString * const kMetricDownloadPercentageKey = @"kCurrentDownloadPercentage";
NSString * const kPreMediateNetwork = @"network-placeholder";

+ (NSDictionary *)baseMetricsForAdUnit:(NSString *)adUnit andNetwork:(NSString *)network
{
    return @{
             kNetworkKey: network,
             @"ad_unit": adUnit,
             @"framework": [HZAdsManager sharedManager].framework ?: @"none",
             kMetricID:[[self class] uniqueIdentifier],
            };
}

- (NSMutableDictionary *)getMetricsForTag:(NSString *)tag adUnit:(NSString *)adUnit network:(NSString *)network {
    if (tag == nil ) tag = @"default";
    NSParameterAssert(adUnit);

    // some timing metrics (e.g. time_from_start_to_show_ad) need to be saved before we have mediated a network
    // they get their own temporary metrics dictionary
    if (!network) {
        return [self getPreMediateMetricsForTag:tag adUnit:adUnit];
    }
    NSParameterAssert(network);

    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:tag adUnit:adUnit network:network];
    if (!self.metricsDict[key]) {
        self.metricsDict[key] = [[[self class] baseMetricsForAdUnit:adUnit andNetwork:network] mutableCopy];
    }

    // if there are any metrics saved before we mediated a network, roll them into this network's metrics now
    HZMetricsKey *const preMediateKey = [[HZMetricsKey alloc] initWithTag:tag adUnit:adUnit network:kPreMediateNetwork];
    if (self.preMediateMetricsDict[preMediateKey]) {
        [self.metricsDict[key] addEntriesFromDictionary:self.preMediateMetricsDict[preMediateKey]];
        [self.preMediateMetricsDict removeObjectForKey:preMediateKey];
    }

    return self.metricsDict[key];
}

- (NSMutableDictionary *)getPreMediateMetricsForTag:(NSString *)tag adUnit:(NSString *)adUnit {
    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:tag adUnit:adUnit network:kPreMediateNetwork];
    if (!self.preMediateMetricsDict[key]) {
        self.preMediateMetricsDict[key] = [@{
                                             @"ad_unit": adUnit,
                                             @"framework": [HZAdsManager sharedManager].framework ?: @"none",
                                             kMetricID: [[self class] uniqueIdentifier],
                                             } mutableCopy];
    }
    return self.preMediateMetricsDict[key];
}

- (void)finishUsingAdWithTag:(NSString *)tag adUnit:(NSString *)adUnit network:(NSString *)network {
    if (tag == nil ) tag = @"default";
    NSParameterAssert(adUnit);
    
    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:tag adUnit:adUnit network:network];
    NSDictionary *const metrics = self.metricsDict[key];
    [[self class] writeMetricToDisk:metrics];
    [self.metricsDict removeObjectForKey:key];
    
}

- (void) removeAdWithProvider:(id <HZMetricsProvider>)provider network:(NSString *)network {
    [self finishUsingAdWithTag:provider.tag adUnit:provider.adUnit network:network];
//    HZMetricsKey *const key = [[HZMetricsKey alloc] initWithTag:object.tag adUnit:object.adUnit network:network];
//    [self.metricsDict removeObjectForKey:key];
}

#pragma mark - Logging Metrics

- (void) logMetricsEvent: (NSString *) eventName value:(id)value withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network {
    if (!value) {
        HZDLog(@"nil value for key %@",eventName);
        return;
    }
    
    BOOL validClass = [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]];
    NSParameterAssert(validClass);
    
    ensureMainQueue(^{
        NSMutableDictionary *d = [self getMetricsForTag:provider.tag adUnit:provider.adUnit network:network];
        d[eventName] = value;
    });

    [[NSNotificationCenter defaultCenter] postNotificationName:@"HZMetricsCached"
                                                        object:nil
                                                      userInfo:nil];
}

- (void) logFetchTimeWithObject:(id <HZMetricsProvider>)provider network:(NSString *)network {
    self.fetchCalledTime = CACurrentMediaTime();
    [self logMetricsEvent:@"fetch" value:@1 withProvider:provider network:network];
}

- (void) logTimeSinceFetchFor:(NSString *)eventName withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceFetchMiliseconds = lround((currentTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:eventName value:@(elapsedtimeSinceFetchMiliseconds) withProvider:provider network:network];
}

- (void) logShowAdWithObject:(id <HZMetricsProvider>)provider network:(NSString *)network{
    [[HZMetrics sharedInstance] logMetricsEvent:@"show_ad_called" value:@1 withProvider:provider network:network];
    self.showAdCalledTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((self.showAdCalledTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:kShowAdTimeSincePreviousRelevantFetchKey value:@(elapsedtimeSinceShowMiliseconds) withProvider:provider network:network];
}

- (void) logTimeSinceShowAdFor:(NSString *)eventname withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.showAdCalledTime)*1000);
    [self logMetricsEvent:eventname value:@(elapsedtimeSinceShowMiliseconds) withProvider:provider network:network];
}

- (void) logDownloadPercentageFor:(NSString *)eventname withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network{
    ensureMainQueue(^{
        NSNumber *downloadPercentage = [self getMetricsForTag:provider.tag adUnit:provider.adUnit network:network][kMetricDownloadPercentageKey];
        if (downloadPercentage) { // If we aren't downloading a video, don't log anything
            [self logMetricsEvent:eventname value:downloadPercentage withProvider:provider network:network];
        }
    });
}

- (void) logTimeSinceStartFor:(NSString *)eventname withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network {
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.startTime)*1000);
    [self logMetricsEvent:eventname value:@(elapsedtimeSinceShowMiliseconds) withProvider:provider network:network];
}

- (void)logIsAvailable:(BOOL)isAvailable withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network {
    if (isAvailable) {
        [[HZMetrics sharedInstance] logMetricsEvent:kIsAvailableStatusKey value:@"is_available" withProvider:provider network:network];
    } else {
        ensureMainQueue(^{
            NSDictionary *const currentMetric = [self getMetricsForTag:provider.tag adUnit:provider.adUnit network:network];
            [self logMetricsEvent:kIsAvailableStatusKey value:metricFailureReason(currentMetric) withProvider:provider network:network];
        });
    }
}

// This isn't actually a metric, but the metric dictionary is a useful place to store the current download percentage for that video ad.
- (void)setDownloadPercentage:(int)downloadPercentage withProvider:(id <HZMetricsProvider>)provider network:(NSString *)network {
    [self logMetricsEvent:kMetricDownloadPercentageKey value:@(downloadPercentage) withProvider:provider network:network];
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
    __block NSArray *metrics = [self getCachedMetrics];
    NSArray *metricIDs = hzMap(metrics, ^NSURL *(NSDictionary *metric) {
        return metric[kMetricID];
    });
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        metrics = [metrics arrayByAddingObject:@{@"start": @1}];
    });
    
    if ([metrics count]) {
        
        NSMutableDictionary *params = [[[self class] staticValuesDict] mutableCopy];
        
        params[@"metrics"] = metrics;
        
        [[HZAPIClient sharedClient] post:kSendMetricsUrl withParams:params success:^(id data) {
            HZDLog(@"# Metrics sent = %lu",(unsigned long)[metrics count]);
            [[self class] clearMetricsWithMetricIDs:metricIDs];
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            HZELog(@"Error from server = %@",error);
        }];
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
    [self.metricsDict enumerateKeysAndObjectsUsingBlock:^(HZMetricsKey *key, NSMutableDictionary *metric, BOOL *stop) {
        const BOOL success = [[self class] writeMetricToDisk:metric];
        HZDLog(@"Able to write metric to disk = %i",success);
    }];
}

+ (void)clearMetricsWithMetricIDs:(NSArray *)metricIDs
{
    for (NSString *metricID in metricIDs) {
        NSURL *metricPath = [self pathToMetricWithID:metricID];
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
        HZELog(@"Error creating directory; error = %@",error);
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
