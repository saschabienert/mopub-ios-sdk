//
//  HZAdsRequestSerializer.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZAdsRequestSerializer.h"
#import "HZDevice.h"
#import "HZUtils.h"
#import "HeyzapAds.h"
#import "HZAvailability.h"

@implementation HZAdsRequestSerializer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(id)parameters error:(NSError *__autoreleasing *)error {
    if ([parameters isKindOfClass:[NSDictionary class]] || parameters == nil) {
        parameters = [[self class] defaultParamsWithDictionary:parameters];
    }
    return [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
}

#pragma mark - Default Parameters

+ (NSMutableDictionary *)defaultParams {
    // Profiling revealed this to be mildly expensive. The values never change so dispatch_once is a good optimization.
    static NSDictionary *defaultParams = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *deviceFormFactor;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            deviceFormFactor = @"tablet";
        } else {
            deviceFormFactor = @"phone";
        }
        
        NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
        versionString = versionString ?: @"";
        
        NSString *publisherID = [HZUtils publisherID] ?: @"";
        
        NSMutableDictionary *params = [@{@"publisher_id": publisherID,
                                         @"publisher_sdk_key": publisherID,
                                         @"device_id": [HZUtils deviceID],
                                         @"app_bundle_id": [[HZDevice currentDevice] bundleIdentifier],
                                         @"app_version": versionString,
                                         @"device_form_factor": deviceFormFactor,
                                         @"platform": @"iphone",
                                         @"sdk_platform": @"iphone",
                                         @"sdk_version": SDK_VERSION,
                                         @"ios_version": [UIDevice currentDevice].systemVersion,
                                         @"os_version": [UIDevice currentDevice].systemVersion,
                                         @"device_type": [HZAvailability platform],
                                         @"advertising_id" : [HZUtils deviceID],
                                         } mutableCopy];
        
        [params addEntriesFromDictionary:[[HZDevice currentDevice] HZIdentifierDictionary]];
        defaultParams = params;
    });
    
    return [defaultParams mutableCopy];
}

+ (NSMutableDictionary *) defaultParamsWithDictionary: (NSDictionary *) dictionary {
    NSMutableDictionary *params = [self defaultParams];
    if (dictionary) {
        [params addEntriesFromDictionary: dictionary];
    }
    return params;
}

@end
