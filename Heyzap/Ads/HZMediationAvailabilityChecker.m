//
//  HZMediationAvailabilityChecker.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationAvailabilityChecker.h"
#import "HZDictionaryUtils.h"
#import "HZBaseAdapter.h"
#import "HZMediationConstants.h"
#import "HZUtils.h"
#import "HZInterstitialVideoConfig.h"

@interface HZMediationAvailabilityChecker()

@property (nonatomic, strong) NSDate *lastInterstitialVideoShownDate;

@property (nonatomic) HZInterstitialVideoConfig *config;

@end

@implementation HZMediationAvailabilityChecker

- (instancetype)initWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig {
    self = [super init];
    if (self) {
        _config = interstitialVideoConfig;
    }
    return self;
}

- (HZBaseAdapter *)firstAdapterWithAdForAdType:(HZAdType)adType adapters:(NSOrderedSet *)adapters optionalForcedNetwork:(Class)forcedNetwork {
    
    NSOrderedSet *preferredMediatorList = [self availableAdaptersForAdType:adType adapters:adapters];
    
    if (forcedNetwork) {
        preferredMediatorList = hzFilterOrderedSet(preferredMediatorList, ^BOOL(HZBaseAdapter *adapter) {
            return [adapter isKindOfClass:forcedNetwork];
        });
    }
        
    const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        return [adapter hasAdForType:adType];
    }];
        
    if (idx != NSNotFound) {
        return preferredMediatorList[idx];
    } else {
        return nil;
    }
}

- (BOOL)withinInterval {
    if (!self.lastInterstitialVideoShownDate) {
        return YES;
    }
    const NSTimeInterval secondsSinceLastInterstitial = [[NSDate date] timeIntervalSinceDate:self.lastInterstitialVideoShownDate];
    return (secondsSinceLastInterstitial * 1000) > self.config.interstitialVideoIntervalMillis;
}

- (NSOrderedSet *)availableAdaptersForAdType:(HZAdType)adType adapters:(NSOrderedSet *)adapters {
    NSOrderedSet *filtered = [self filterAdaptersForInterstitialVideo:adapters adType:adType];
    
    NSIndexSet *indexes = [filtered indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        return [adapter supportsAdType:adType];
    }];
    
    return [NSOrderedSet orderedSetWithArray:[filtered objectsAtIndexes:indexes]];
}

- (NSOrderedSet *)filterAdaptersForInterstitialVideo:(NSOrderedSet *)adapters adType:(HZAdType)adType {
    if ((!self.lastInterstitialVideoShownDate && self.config.interstitialVideoEnabled) || adType != HZAdTypeInterstitial) {
        return adapters;
    }
    
    const BOOL shouldAllowInterstitialVideo = [self withinInterval] && self.config.interstitialVideoEnabled;
    
    NSIndexSet *indexes = [adapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        return shouldAllowInterstitialVideo || !adapter.isVideoOnlyNetwork;
    }];
    
    return [NSOrderedSet orderedSetWithArray:[adapters objectsAtIndexes:indexes]];
}

- (void)updateWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig {
    self.config = interstitialVideoConfig;
}

- (void)didShowInterstitialVideo {
    self.lastInterstitialVideoShownDate = [NSDate date];
}

- (NSOrderedSet *)parseMediateIntoAdapters:(NSDictionary *)mediateDictionary setupAdapterClasses:(NSSet *)setupAdapterClasses adType:(HZAdType)adType {
    NSError *error;
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:mediateDictionary error:&error];
    
    NSMutableOrderedSet *chosenNetworks = [NSMutableOrderedSet orderedSet];
    
    for (NSDictionary *network in networks) {
        NSString *networkName = network[@"network"];
        NSSet *creativeTypes = [NSSet setWithArray:network[@"creative_types"]];
        Class adapter = [HZBaseAdapter adapterClassForName:networkName];
        HZBaseAdapter *adapterInstance = (HZBaseAdapter *)[adapter sharedInstance];
        
        if ([setupAdapterClasses containsObject:adapter]) {
            if (hzCreativeTypeSetContainsAdType(creativeTypes,adType)) {
                [chosenNetworks addObject:adapterInstance];
            }
            // Interstitial video
            if (adType == HZAdTypeInterstitial && hzCreativeTypeSetContainsAdType(creativeTypes, HZAdTypeVideo)) {
                [chosenNetworks addObject:adapterInstance];
            }
        }
    }
    return chosenNetworks;
}


// Check error macro for networks being nil/empty

//NSMutableOrderedSet *adapters = [NSMutableOrderedSet orderedSet];
//for (NSDictionary *network in networks) {
//    NSString *networkName = network[@"network"];
//    Class adapter = [HZBaseAdapter adapterClassForName:networkName];
//    if (adapter
//        && [adapter isSDKAvailable]
//        && [setupMediators containsObject:[adapter sharedInstance]]
//        && [(HZBaseAdapter *)[adapter sharedInstance] supportsAdType:adType]) {
//        
//        HZBaseAdapter *instance = (HZBaseAdapter *)[adapter sharedInstance];
//        if (adType != HZAdTypeInterstitial || _interstitialVideoEnabled || !instance.isVideoOnlyNetwork) {
//            [adapters addObject:[adapter sharedInstance]];
//        }
//    }
//}

@end
