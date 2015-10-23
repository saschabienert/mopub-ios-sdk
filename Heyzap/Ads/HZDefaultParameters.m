//
//  HZDefaultParameters.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZDefaultParameters.h"
#import "HZDevice.h"
#import "HZUtils.h"
#import "HeyzapAds.h"
#import "HZAvailability.h"

@implementation HZDefaultParameters

NSString * const kHZEnvironmentParamsKey = @"environment_params";

+ (NSMutableDictionary *)baseDefaultParams {
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
                                         @"device_id": [HZDevice HZadvertisingIdentifier],
                                         @"app_bundle_id": [HZDevice bundleIdentifier],
                                         @"app_version": versionString,
                                         @"device_form_factor": deviceFormFactor,
                                         @"platform": @"iphone",
                                         @"sdk_platform": @"iphone",
                                         @"sdk_version": SDK_VERSION,
                                         @"ios_version": [HZDevice systemVersion],
                                         @"os_version": [HZDevice systemVersion],
                                         @"device_type": [HZAvailability platform],
                                         @"advertising_id" : [HZDevice HZadvertisingIdentifier],
                                         @"app_name": [HZDevice appName],
                                         } mutableCopy];
        
        [params addEntriesFromDictionary:[HZDevice HZIdentifierDictionary]];
        defaultParams = params;
    });
    
    return [defaultParams mutableCopy];
}

+ (NSMutableDictionary *)mediationDefaultParams {
    NSMutableDictionary *defaults = [self baseDefaultParams];
    
    static NSDictionary *mediationDefaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediationDefaults = @{
                              @"external_package":[HZDevice bundleIdentifier],
                              @"networks":[HeyzapMediation commaSeparatedAdapterList],
                              };
    });
    
    [defaults addEntriesFromDictionary:mediationDefaults];
    
    return defaults;
}

@end
