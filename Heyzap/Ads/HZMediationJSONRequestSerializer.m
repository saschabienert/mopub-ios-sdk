//
//  HZMediationJSONRequestSerializer.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationJSONRequestSerializer.h"
#import "HZMediationRequestSerializer.h"
#import "HZDefaultParameters.h"

@implementation HZMediationJSONRequestSerializer

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

+ (NSMutableDictionary *) defaultParamsWithDictionary: (NSDictionary *) dictionary {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    params[kHZEnvironmentParamsKey] = [HZDefaultParameters mediationDefaultParams];
    return params;
}

@end
