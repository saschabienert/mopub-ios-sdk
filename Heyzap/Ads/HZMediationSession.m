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
        return [adapter hasAdForType:self.adType tag:self.tag];
    }];
    
    if (idx != NSNotFound) {
        return preferredMediatorList[idx];
    } else {
        return nil;
    }
}

#pragma mark - Reporting Events to the server

NSString *const kHZImpressionIDKey = @"tracking_id";
NSString *const kHZNetworkKey = @"network";

- (void)reportSuccessfulFetchUpToAdapter:(HZBaseAdapter *)chosenAdapter
{
    
    const NSUInteger chosenIndex = [self.chosenAdapters indexOfObject:chosenAdapter];
    NSArray *adapterList = [self.chosenAdapters objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, chosenIndex+1)]];
    for (HZBaseAdapter *adapter in adapterList) {
        NSNumber *const success = (adapter == [adapterList lastObject]) ? @1 : @0; // Last adapter was successful
        [[HZMediationAPIClient sharedClient] post:@"fetch" withParams:@{@"success": success, kHZNetworkKey : [adapter name]} success:^(id json) {
            HZDLog(@"Success reporting fetch");
        } failure:^(NSError *error) {
            HZDLog(@"Error reporting fetch = %@",error);
        }];
    }
}

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter
{
    [[HZMediationAPIClient sharedClient] post:@"click"
                                 withParams:@{kHZImpressionIDKey: self.impressionID,
                                              kHZNetworkKey: [adapter name]}
                                    success:^(id json) {
        HZDLog(@"Success reporting click");
    } failure:^(NSError *error) {
        HZDLog(@"Error reporting click = %@",error);
    }];
}

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter
{
    [[HZMediationAPIClient sharedClient] post:@"impression"
                                 withParams:@{kHZImpressionIDKey: self.impressionID,
                                              kHZNetworkKey: [adapter name]}
                                    success:^(id json) {       
        HZDLog(@"Success reporting impression");
    } failure:^(NSError *error) {
        HZDLog(@"Error reporting impression = %@",error);
    }];
}

@end
