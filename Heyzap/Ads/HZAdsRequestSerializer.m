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
#import "HZDefaultParameters.h"

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

+ (NSMutableDictionary *) defaultParamsWithDictionary: (NSDictionary *) dictionary {
    NSMutableDictionary *params = [HZDefaultParameters baseDefaultParams];
    if (dictionary) {
        [params addEntriesFromDictionary: dictionary];
    }
    return params;
}

@end
