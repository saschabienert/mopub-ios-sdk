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

#define METRICS_URL @"/mobile/track_sdk_event" //change url
NSString * const kSendMetricsUrl = @"/in_game_api/metrics/export";
NSString * const kDataFileName = @"metrics.hz";

static NSMutableDictionary *metricsInstanceDict = nil;

@interface HZMetrics()
@property (nonatomic, strong) NSMutableDictionary *metrics;
@property (nonatomic, strong) NSMutableDictionary *untypedMetrics;
@property (nonatomic, strong) NSMutableDictionary *metricsTagDict;
@property (nonatomic, strong) NSMutableDictionary *metricsBeingSent;
@property (nonatomic, strong) NSMutableDictionary *metricsIDDict;
@property (nonatomic) BOOL enabled;
@property (nonatomic) NSInteger id;
@property (nonatomic) CFTimeInterval fetchCalledTime;
@property (nonatomic) CFTimeInterval showAdCalledTime;
@property (nonatomic) CFTimeInterval startTime;
@end

@implementation HZMetrics

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
    self.enabled = NO;
    self.metricsBeingSent = [[NSMutableDictionary alloc] init];
    self.metricsTagDict = [[NSMutableDictionary alloc] init];
    self.metricsIDDict = [[NSMutableDictionary alloc] init];;
    self.untypedMetrics = [[NSMutableDictionary alloc] init];
    self.startTime = CACurrentMediaTime();
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(sendCachedMetrics)
                                                 name: UIApplicationWillTerminateNotification object: nil];
    return self;
}

- (NSMutableDictionary *) adDictForType:(NSString *)type{
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    if (type != nil) newDict[@"ad-unit"] = type;
    newDict[@"metric-id"] = @(arc4random());
    NSString *stringID = [NSString stringWithFormat: @"%@", newDict[@"metric-id"]];
    self.metricsIDDict[stringID] = newDict;
    return newDict;
}

- (NSMutableDictionary *) getMetricsForTag:(NSString *)tag andType:(NSString *)type {
    if (tag == nil ) tag = @"default";
    //make or get instance from instace dict (cache 1)
    if (self.metricsTagDict[tag]){
        NSMutableDictionary *dict = self.metricsTagDict[tag][type];
        if(dict){
            return dict;
        } else if (type != nil){
            if (self.untypedMetrics[tag] != nil){
                self.metricsTagDict[tag][type] = [NSMutableDictionary dictionaryWithDictionary:self.untypedMetrics[tag]];
                self.metricsTagDict[tag][type][@"ad-unit"] = type;
                [self.untypedMetrics removeAllObjects];
            } else {
                self.metricsTagDict[tag][type] = [self adDictForType:type];
            }
            return self.metricsTagDict[tag][type];
        } else {
            if (self.untypedMetrics[tag] == nil) self.untypedMetrics[tag] = [self adDictForType:type];
            return self.untypedMetrics[tag];
        }
    } else {
        self.metricsTagDict[tag] = [[NSMutableDictionary alloc] init];
        if (type == nil) {
            if (self.untypedMetrics[tag] == nil) self.untypedMetrics[tag] = [[NSMutableDictionary alloc] init];
            return self.untypedMetrics[tag];
        } else {
            self.metricsTagDict[tag][type] = [self adDictForType:type];
            return self.metricsTagDict[tag][type];
        }
    }
}

- (void) removeAdForTag:(NSString *)tag andType:(NSString *)type {
    if(self.metricsTagDict[tag]){
        [self.metricsTagDict[tag] removeObjectForKey:type];
    }
}

- (void) logMetricsEvent: (NSString *) eventName withValue:(id)value forTag:(NSString *)tag andType:(NSString *)type {
    NSMutableDictionary *d = [self getMetricsForTag:tag andType:type];
    d[eventName] = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"HZMetricsCached"
                                                        object:nil
                                                      userInfo:self.metricsTagDict];
        [self cacheMetrics];
}

- (void) logFetchTimeForTag: (NSString *) tag andType:(NSString *) type {
    self.fetchCalledTime = CACurrentMediaTime();
    [self logMetricsEvent:@"fetch" withValue:@1 forTag:tag andType:type];
}

- (void) logTimeSinceFetchFor:(NSString *)eventName forTag:(NSString *)tag andType:(NSString *)type{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceFetchMiliseconds = lround((currentTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:eventName withValue:@(elapsedtimeSinceFetchMiliseconds) forTag:tag andType:type];
}

- (void) logShowAdForTag:(NSString *)tag andType:(NSString *)type{
    [[HZMetrics sharedInstance] logMetricsEvent:@"show-ad" withValue:@1 forTag:tag andType:type];
    self.showAdCalledTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((self.showAdCalledTime - self.fetchCalledTime)*1000);
    [self logMetricsEvent:@"show-ad-time-since-fetch" withValue:@(elapsedtimeSinceShowMiliseconds) forTag:tag andType:type];
}

- (void) logTimeSinceShowAdFor:(NSString *)eventname forTag:(NSString *)tag andType:(NSString *)type{
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.showAdCalledTime)*1000);
    [self logMetricsEvent:eventname withValue:@(elapsedtimeSinceShowMiliseconds) forTag:tag andType:type];
}

- (void) logDownloadPercentageFor:(NSString *)eventname forTag:(NSString *)tag andType:(NSString *)type{
    [self logMetricsEvent:eventname withValue:@(self.downloadPercentage) forTag:tag andType:type];
}

- (void) logTimeSinceStartFor:(NSString *)eventname forTag:(NSString *)tag andType:(NSString *)type {
    CFTimeInterval currentTime = CACurrentMediaTime();
    int64_t elapsedtimeSinceShowMiliseconds = lround((currentTime - self.startTime)*1000);
    [self logMetricsEvent:eventname withValue:@(elapsedtimeSinceShowMiliseconds) forTag:tag andType:type];
}

- (NSMutableDictionary *) addConstantsToDict:(NSMutableDictionary *)dict{
    NSString *deviceFormFactor;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        deviceFormFactor = @"tablet";
    } else {
        deviceFormFactor = @"phone";
    }
    dict[@"device-type"] = deviceFormFactor;
    
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    NSString *carrierName = carrier.carrierName ? carrier.carrierName : @"";
    dict[@"carrier"] = carrierName;
    
    dict[@"os_version"] = [UIDevice currentDevice].systemVersion;
    dict[@"connectivity"] = [[HZDevice currentDevice] HZConnectivityType] == nil ? @0 : @1;
    dict[@"conection_type"] = [[HZDevice currentDevice] HZConnectivityType] ?: @"no_internet";
    return dict;
}

- (NSMutableDictionary *)formatedMetricsToSave {
    NSMutableArray *metricsArray = [[NSMutableArray alloc] init];
    NSEnumerator *idEnumerator = [self.metricsIDDict keyEnumerator];
    NSString *metricID;
    while ((metricID = [idEnumerator nextObject])) {
        [metricsArray addObject:self.metricsIDDict[metricID]];
    }
    NSMutableDictionary *metricsToSave = [NSMutableDictionary dictionaryWithObject:metricsArray forKey:@"metrics"];
    return metricsToSave;
}

- (void)cacheMetrics {
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [libraryDir stringByAppendingPathComponent:kDataFileName];
    NSMutableDictionary *metricsToSave = [self formatedMetricsToSave];
    NSLog(@"Caching: %@", metricsToSave);
    NSMutableDictionary *dataToSave = [self addConstantsToDict:metricsToSave];
    if (![dataToSave writeToFile:filePath atomically:YES]){
        NSLog(@"%@", @"error writing file");
    } else {
        NSLog(@"%@", @"wrote to file!");
    }
    NSLog(@"Contents of File: %@", [NSMutableDictionary dictionaryWithContentsOfFile:filePath]);
}

- (NSMutableDictionary *)getCachedMetrics {
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [libraryDir stringByAppendingPathComponent:kDataFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]){
        return [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    } else {
        return nil;
    }
}

- (void) clearCache {
    [self.metricsIDDict removeAllObjects];
    [self.metricsTagDict removeAllObjects];
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [libraryDir stringByAppendingPathComponent:kDataFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:nil];
}


//forground
- (void)sendCachedMetrics {
    //if (self.enabled && self.metricsBeingSent.count == 0){
        NSMutableDictionary *savedMetrics = [self getCachedMetrics];
        if ((savedMetrics != nil) && ([savedMetrics[@"metrics"] count] > 0)){
            [[HZAPIClient sharedClient] post: kSendMetricsUrl  withParams: savedMetrics success:^(id data) {
                [self.metricsTagDict removeAllObjects];
                [self clearCache];
            } failure:^(NSError *error) {
            }];
        }
    //}
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
