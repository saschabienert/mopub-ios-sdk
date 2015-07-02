//
//  HZHeyzapExchangeRequestSerializer.m
//  Heyzap
//
//  Created by Monroe Ekilah on 7/1/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeRequestSerializer.h"
#import "HZDevice.h"
#import "HZUtils.h"
#import "HeyzapAds.h"
#import "HZAvailability.h"
#import "HZHeyzapExchangeClient.h"

@implementation HZHeyzapExchangeRequestSerializer

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
        
        NSString *deviceModel;
        NSNumber *deviceType; //see table 6.16 of http://www.iab.net/media/file/OpenRTBAPISpecificationVersion2_2.pdf
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            deviceModel = @"iPad";
            deviceType = @(5); // 5 == Tablet
        } else {
            deviceModel = @"iPhone";
            deviceType = @(4); // 4 == Phone
        }
        
        UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        NSString* userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] ?: @"";
        
        NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
        versionString = versionString ?: @"";
        
        NSString *publisherID = [HZUtils publisherID] ?: @"";
        
        NSMutableDictionary *params = [@{@"app_platform": @(1),//iOS=1 (enum: ANDROID(0), IOS(1), AMAZON(2) )
                                         @"app_bundle": [[HZDevice currentDevice] bundleIdentifier],
                                         @"app_version": versionString,
                                         @"app_sdk_key": publisherID,
                                         @"publisher_id": publisherID,//monroe: remove this later, server still expecting it
                                         @"device_ua": userAgent,
                                         @"device_carrier": [[HZDevice currentDevice] HZCarrierName],
                                         @"device_make": @"Apple",
                                         @"device_model": deviceModel,
                                         @"device_language": [[NSLocale preferredLanguages] objectAtIndex:0],
                                         @"device_os": @"iOS",
                                         @"device_osv": [HZDevice systemVersion],
                                         @"device_connectiontype": @([[HZDevice currentDevice] getHZOpenRTBConnectionType]),
                                         @"device_ifa": [HZUtils deviceID],
                                         @"device_devicetype": deviceType,
                                         @"sdk_version": SDK_VERSION,
                                         @"video_delivery": @"2",//comma separated list of delivery methods STREAMING(1),PROGRESSIVE(2)
                                         @"video_playbackmethod": @"1",//comma separated list of playback methods: AUTO_PLAY_SOUND_ON_VALUE(1), AUTO_PLAY_SOUND_OFF_VALUE(2), CLICK_TO_PLAY_VALUE(3), MOUSE_OVER_VALUE(4)
                                         } mutableCopy];
        
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
