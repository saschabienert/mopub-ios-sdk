//
//  HZMediationRequestSerializer.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationRequestSerializer.h"
#import "HeyzapMediation.h"
#import "HZDevice.h"
#import "HZMediationAPIClient.h"
#import "HZUtils.h"
#import "HZDefaultParameters.h"

@implementation HZMediationRequestSerializer

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
        
        // `/complete` is for rewarded video callbacks. we have some extra work to do here for the security of the server-side callbacks
        if ([URLString isEqualToString:[NSString stringWithFormat:@"%@complete", kHZMediationAPIBaseURLString]]) {
            // the server expects the `extras` param to be the SHA-1 of the url & params (params in alphabetical order)
            NSArray *sortedKeys = [[parameters allKeys] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc]initWithKey:@"self" ascending:YES ]]];
            
            // construct URL string to compute hash with
            NSArray *sortedKeysAndValues = hzMap(sortedKeys, ^NSString *(NSString *key){
                return [NSString stringWithFormat:@"%@=%@", key, [parameters objectForKey:key]];
            });
            NSMutableString *url = [NSMutableString stringWithFormat:@"%@?%@", URLString, [sortedKeysAndValues componentsJoinedByString:@"&"]];
            
            NSMutableDictionary *newParams = [parameters mutableCopy];
            newParams[@"extras"] = [HZUtils SHA1ForString:url];
            parameters = newParams;
        }
    }
    return [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
}

+ (NSMutableDictionary *) defaultParamsWithDictionary: (NSDictionary *) dictionary {
    NSMutableDictionary *params = [HZDefaultParameters mediationDefaultParams];
    if (dictionary) {
        [params addEntriesFromDictionary: dictionary];
    }
    return params;
}

@end
