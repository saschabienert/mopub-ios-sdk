//
//  HZMediationLoadData.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationLoadData.h"
#import "HZDictionaryUtils.h"
#import "HZBaseAdapter.h"
#import "HZMediationConstants.h"

@implementation HZMediationLoadData

#define CHECK_NOT_NIL1(value) do { \
if (value == nil) { \
return nil; \
} \
} while (0)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    NSParameterAssert(error);
    self = [super init];
    if (self) {
        
        _networkName = [HZDictionaryUtils objectForKey:@"network" ofClass:[NSString class] dict:dictionary error:error];
        CHECK_NOT_NIL1(_networkName);
        
        _adapterClass = [HZBaseAdapter adapterClassForName:_networkName];
        if (!_adapterClass) {
            *error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The specified network (%@) isn't supported by this SDK",_networkName]}];
            return nil;
        }
        
        _load = [[HZDictionaryUtils hzObjectForKey:@"load" ofClass:[NSNumber class] default:@1 withDict:dictionary] unsignedIntegerValue];
        
        double timeoutMillis = [[HZDictionaryUtils hzObjectForKey:@"ttl" ofClass:[NSNumber class] default:@10000 withDict:dictionary] doubleValue];
        _timeout = timeoutMillis / 1000;
        
        NSArray *creativeTypes = [HZDictionaryUtils objectForKey:@"creative_types" ofClass:[NSArray class] dict:dictionary error:error];
        CHECK_NOT_NIL1(creativeTypes);
        
        _creativeTypeSet = [NSSet setWithArray:creativeTypes];
    }
    return self;
}

- (NSString *)debugDescription {
    NSMutableString *description = [NSMutableString stringWithString:[super debugDescription]];
    [description appendFormat:@" load = %lu",(unsigned long)self.load];
    [description appendFormat:@" timeout = %g",self.timeout];
    [description appendFormat:@" network = %@",self.networkName];
    [description appendFormat:@" creativeTypes = %@",self.creativeTypeSet];
    return description;
}

@end
