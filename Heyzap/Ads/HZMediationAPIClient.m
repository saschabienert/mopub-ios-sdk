//
//  MicahClient.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/28/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationAPIClient.h"
#import "HeyzapMediation.h"

NSString * const kHZAdsAPIBaseURLString = @"http://med.heyzap.com/";

@implementation HZMediationAPIClient

+ (HZMediationAPIClient *)sharedClient {
    static HZMediationAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedClient = [[HZMediationAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZAdsAPIBaseURLString]];
    });
    
    return _sharedClient;
}

+ (NSMutableDictionary *)defaultParamsWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *defaults = [super defaultParamsWithDictionary:dictionary];
    defaults[@"external_package"] = [[NSBundle mainBundle] bundleIdentifier];
    defaults[@"networks"] = [HeyzapMediation commaSeparatedAdapterList];
    
    return defaults;
}

@end
