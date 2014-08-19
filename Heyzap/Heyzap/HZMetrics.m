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

NSString * const kSendMetricsUrl = @"/in_game_api/metrics/export";

@interface HZMetrics()
@property (nonatomic, strong) NSMutableDictionary *metricsDict;
@property (nonatomic) CFTimeInterval fetchCalledTime;
@property (nonatomic) CFTimeInterval showAdCalledTime;
@property (nonatomic) CFTimeInterval startTime;
@end

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
    // Send metrics on next run loop iteration.
    [self performSelector:@selector(sendCachedMetrics) withObject:nil afterDelay:1];
    
    return self;
}

NSString * const kMetricID = @"metricIdentifier";

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
    [[HZMetrics sharedInstance] logMetricsEvent:@"show-ad" value:@1 tag:tag type:type];
    self.showAdCalledTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((self.showAdCalledTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:@"show-ad-time-since-fetch" value:@(elapsedtimeSinceShowMiliseconds) tag:tag type:type];
}

- (void) logTimeSinceShowAdFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.showAdCalledTime)*1000);
    [self logMetricsEvent:eventname value:@(elapsedtimeSinceShowMiliseconds) tag:tag type:type];
}

- (void) logDownloadPercentageFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type{
    [self logMetricsEvent:eventname value:@(self.downloadPercentage) tag:tag type:type];
}

- (void) logTimeSinceStartFor:(NSString *)eventname tag:(NSString *)tag type:(NSString *)type {
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.startTime)*1000);
    [self logMetricsEvent:eventname value:@(elapsedtimeSinceShowMiliseconds) tag:tag type:type];
}

+ (NSDictionary *) staticValuesDict {
    return @{
      @"carrier": [[CTTelephonyNetworkInfo alloc] init].subscriberCellularProvider.carrierName ?: @"",
      @"connectivity": [[HZDevice currentDevice] HZConnectivityType] == nil ? @0 : @1,
      @"conection_type": [[HZDevice currentDevice] HZConnectivityType] ?: @"no_internet",
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

#pragma mark - dealloc

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
