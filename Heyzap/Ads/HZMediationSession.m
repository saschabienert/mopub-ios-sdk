//
//  HZMediationSession.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationSession.h"
#import "HZDictionaryUtils.h"
#import "HZBaseAdapter.h"
#import "HZMediationConstants.h"
#import "HZMediationAPIClient.h"
#import "HZLog.h"

@interface HZMediationSession()

#pragma mark - Properties from the client
@property (nonatomic) HZAdType adType;
@property (nonatomic, strong) NSString *tag;

#pragma mark - Properties from the server
@property (nonatomic, strong) NSDictionary *originalJSON;
@property (nonatomic, strong) NSString *impressionID;
@property (nonatomic, strong) NSOrderedSet *chosenAdapters;

/**
 *  Returns the SDK version if present, otherwise defaults to empty string.
 *
 *  @param version the version
 *
 *  @return Guaranteed non-nil string.
 */
NSString * sdkVersionOrDefault(NSString *const version);

@end

@implementation HZMediationSession

#define CHECK_NOT_NIL(value) do { \
if (value == nil) { \
*error = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:nil]; \
return nil; \
} \
} while (0)


- (instancetype)initWithJSON:(NSDictionary *)json setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error
{
    NSParameterAssert(error != NULL);
    
    self = [super init];
    if (self) {
        _originalJSON = json;
        CHECK_NOT_NIL(_originalJSON);
        _adType = adType;
        _tag = tag;
        CHECK_NOT_NIL(_tag);
        
        _impressionID = [HZDictionaryUtils objectForKey:@"id" ofClass:[NSString class] dict:json error:error];
        CHECK_NOT_NIL(_impressionID);
        
            
        // Check error macro for impression ID being nil.
        
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
        CHECK_NOT_NIL(networks);
        // Check error macro for networks being nil/empty
        
        NSMutableOrderedSet *adapters = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *network in networks) {
            NSString *networkName = network[@"network"];
            Class adapter = [HZBaseAdapter adapterClassForName:networkName];
            if (adapter
                && [adapter isSDKAvailable]
                && [setupMediators containsObject:[adapter sharedInstance]]
                && [[adapter sharedInstance] supportsAdType:adType]) {
                
                [adapters addObject:[adapter sharedInstance]];
                
                
            }
        }
        
        self.chosenAdapters = adapters;
        HZDLog(@"Available SDKs for this fetch are = %@",self.chosenAdapters);
    }
    return self;
}

- (BOOL)hasAd
{
    return [self firstAdapterWithAd] != nil;
}

- (HZBaseAdapter *)firstAdapterWithAd
{
    
    NSArray *preferredMediatorList = [self.chosenAdapters array];
    
    const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        BOOL hasAd = [adapter hasAdForType:self.adType tag:self.tag];
        if (!hasAd) {
            if ([adapter supportedAdFormats] & self.adType) {
                [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kNoAdAvailableValue withProvider:self network:[adapter name]];
            } else {
                [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kNotCachedAndNotAFetchableAdUnitValue withProvider:self network:[adapter name]];
            }
        } else {
            [[HZMetrics sharedInstance] logMetricsEvent:kShowAdResultKey value:kFullyCachedValue withProvider:self network:[adapter name]];
        }
        return hasAd;
    }];
    
    if (idx != NSNotFound) {
        return preferredMediatorList[idx];
    } else {
        return nil;
    }
}

- (NSString *) adUnit {
    return NSStringFromAdType(_adType);
}

#pragma mark - Reporting Events to the server

NSString *const kHZImpressionIDKey = @"tracking_id";
NSString *const kHZNetworkKey = @"network";
NSString *const kHZNetworkVersionKey = @"network_version";
/**
 *  The dictionary key for the position of a network within the list received from the server; for the list [chartboost, applovin], chartboost is 0.
 */
NSString *const kHZOrdinalKey = @"ordinal";

- (void)reportSuccessfulFetchUpToAdapter:(HZBaseAdapter *)chosenAdapter
{
    
    const NSUInteger chosenIndex = [self.chosenAdapters indexOfObject:chosenAdapter];
    NSArray *adapterList = [self.chosenAdapters objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, chosenIndex+1)]];
    
    [adapterList enumerateObjectsUsingBlock:^(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        NSNumber *const success = (adapter == [adapterList lastObject]) ? @1 : @0; // Last adapter was successful
        [[HZMediationAPIClient sharedClient] post:@"fetch"
                                       withParams:@{@"success": success,
                                                    kHZOrdinalKey : @(idx),
                                                    kHZNetworkKey : [adapter name],
                                                    kHZNetworkVersionKey: sdkVersionOrDefault(adapter.sdkVersion),
                                                    }
                                          success:^(id json) {
            HZDLog(@"Success reporting fetch");
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            HZDLog(@"Error reporting fetch = %@",error);
        }];
    }];
}

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter
{
    const NSUInteger ordinal = [self.chosenAdapters indexOfObject:adapter];
    [[HZMediationAPIClient sharedClient] post:@"click"
                                 withParams:@{kHZImpressionIDKey: self.impressionID,
                                              kHZNetworkKey: [adapter name],
                                              kHZOrdinalKey : @(ordinal),
                                              kHZNetworkVersionKey: sdkVersionOrDefault(adapter.sdkVersion),
                                              }
                                    success:^(id json) {
        HZDLog(@"Success reporting click");
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZDLog(@"Error reporting click = %@",error);
    }];
}

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter
{
    const NSUInteger ordinal = [self.chosenAdapters indexOfObject:adapter];
    [[HZMediationAPIClient sharedClient] post:@"impression"
                                 withParams:@{kHZImpressionIDKey: self.impressionID,
                                              kHZNetworkKey: [adapter name],
                                              kHZOrdinalKey: @(ordinal),
                                              kHZNetworkVersionKey: sdkVersionOrDefault(adapter.sdkVersion),
                                              }
                                    success:^(id json) {       
        HZDLog(@"Success reporting impression");
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        HZDLog(@"Error reporting impression = %@",error);
    }];
}

NSString * sdkVersionOrDefault(NSString *const version) {
    return version ?: @"";
}

@end
