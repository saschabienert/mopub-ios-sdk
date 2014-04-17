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
#import "MediationAPIClient.h"

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

- (instancetype)initWithJSON:(NSDictionary *)json setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error
{
    self = [super init];
    if (self) {
        _originalJSON = json;
        _adType = adType;
        _tag = tag;
        
        _impressionID = [HZDictionaryUtils objectForKey:@"tracking_id" ofClass:[NSString class] dict:json error:error];
        // Check error macro for impression ID being nil.
        
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
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
    }
    return self;
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

- (void)reportClickForAdapter:(HZBaseAdapter *)adapter
{
    [[MediationAPIClient sharedClient] post:@"click"
                                 withParams:@{kHZImpressionIDKey: self.impressionID,
                                              kHZNetworkKey: [adapter name]}
                                    success:^(id json) {
        NSLog(@"click was successful");
    } failure:^(NSError *error) {
        NSLog(@"Click failed");
    }];
}

- (void)reportImpressionForAdapter:(HZBaseAdapter *)adapter
{
    [[MediationAPIClient sharedClient] post:@"impression"
                                 withParams:@{kHZImpressionIDKey: self.impressionID,
                                              kHZNetworkKey: [adapter name]}
                                    success:^(id json) {
        NSLog(@"impression was successful");
    } failure:^(NSError *error) {
        NSLog(@"Failed to report impression to Heyzap, error = %@",error);
    }];
}

@end
