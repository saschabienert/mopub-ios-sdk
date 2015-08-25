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
#import "HZSegmentationController.h"
#import "HZInterstitialVideoConfig.h"
#import "HZMediationPersistentConfig.h"

@interface HZMediationAvailabilityChecker()

@property (nonatomic, strong) NSDate *lastInterstitialVideoShownDate;
@property (nonatomic) HZInterstitialVideoConfig *config;
@property (nonatomic) id<HZMediationPersistentConfigReadonly> persistentConfig;

@end


@implementation HZMediationAvailabilityChecker


#pragma mark - Init

- (instancetype)initWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig {
    self = [super init];
    if (self) {
        _config = interstitialVideoConfig;
        _persistentConfig = persistentConfig;
    }
    return self;
}


#pragma mark - External Setup / Updates

- (void)updateWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig {
    self.config = interstitialVideoConfig;
}

- (void)didShowInterstitialVideo {
    self.lastInterstitialVideoShownDate = [NSDate date];
}


#pragma mark - External Availability Checks 

- (NSOrderedSet *)availableAndAllowedAdaptersForAdType:(HZAdType)adType tag:(NSString *)tag adapters:(NSOrderedSet *)adapters segmentationController:(HZSegmentationController *)segmentationController {
    NSSet *allowedCreativeTypes = [self creativeTypesAllowedForAdType:adType];
    
    NSIndexSet *indexes = [adapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        for(NSNumber *allowedCreativeTypeNumber in allowedCreativeTypes) {
            HZCreativeType allowedCreativeType = hzCreativeTypeFromNSNumber(allowedCreativeTypeNumber);
            if([adapter supportsCreativeType:allowedCreativeType] && [adapter hasCredentialsForCreativeType:allowedCreativeType] && [self.persistentConfig isNetworkEnabled:[adapter name]] && [segmentationController adapterHasAllowedAd:adapter forCreativeType:allowedCreativeType tag:tag]) return YES;
        }
        
        return NO;
    }];
    
    return [NSOrderedSet orderedSetWithArray:[adapters objectsAtIndexes:indexes]];
}


#pragma mark - Externally Called on Show

- (NSOrderedSet *)parseMediateIntoAdaptersForShow:(NSDictionary *)mediateDictionary setupAdapterClasses:(NSSet *)setupAdapterClasses adType:(HZAdType)adType {
    NSError *error;
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:mediateDictionary error:&error];
    
    NSMutableOrderedSet *chosenNetworks = [NSMutableOrderedSet orderedSet];
    
    // check what creative types the requested ad type can show right now
    NSSet *creativeTypesAllowed = [self creativeTypesAllowedForAdType:adType];
    
    for (NSDictionary *network in networks) {
        NSString *networkName = network[@"network"];
        NSSet *creativeTypeStringsForNetwork = [NSSet setWithArray:network[@"creative_types"]]; // networks can have multiple creative types in the mediation response, or a separate entry per creative type. either way, they're in an array in the response.
        Class adapter = [HZBaseAdapter adapterClassForName:networkName];
        HZBaseAdapter *adapterInstance = [adapter sharedAdapter];
        
        if ([setupAdapterClasses containsObject:adapter]) {
            // add each network/score/creativeType triplet to the retrun value for each creativeType in the network's response set that matches a currently-allowed creativeType, if the network is setup & it supports the creativeType
            for (NSNumber * creativeTypeNumber in creativeTypesAllowed) {
                HZCreativeType creativeType = hzCreativeTypeFromNSNumber(creativeTypeNumber);
                
                if (hzCreativeTypeStringSetContainsCreativeType(creativeTypeStringsForNetwork, creativeType) && [adapterInstance supportsCreativeType:creativeType] && [adapterInstance hasCredentialsForCreativeType:creativeType] && [self.persistentConfig isNetworkEnabled:[adapterInstance name]]) {
                    [chosenNetworks addObject:[[HZMediationAdapterWithCreativeTypeScore alloc] initWithAdapter:adapterInstance creativeType:creativeType score:[adapterInstance latestMediationScoreForCreativeType:creativeType]]];
                }
            }
        }
    }
    return chosenNetworks;
}

- (HZMediationAdapterWithCreativeTypeScore *)firstAdapterWithAdForTag:(NSString *)tag adaptersWithScores:(NSOrderedSet *)adaptersWithScores optionalForcedNetwork:(Class)forcedNetwork segmentationController:(HZSegmentationController *)segmentationController {
    if (forcedNetwork) {
        adaptersWithScores = hzFilterOrderedSet(adaptersWithScores, ^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore) {
            return [[adapterWithScore adapter] isKindOfClass:forcedNetwork];
        });
    }
    
    const NSUInteger idx = [adaptersWithScores indexOfObjectPassingTest:^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore, NSUInteger idx, BOOL *stop) {
        if([segmentationController adapterHasAllowedAd:[adapterWithScore adapter] forCreativeType:[adapterWithScore creativeType] tag:tag]) {
           return YES;
        }
        return NO;
    }];
        
    if (idx != NSNotFound) {
        return adaptersWithScores[idx];
    } else {
        return nil;
    }
}


#pragma mark - Utilities

- (BOOL) hasEnoughTimePassedSinceLastInterstitialVideo {
    if (!self.lastInterstitialVideoShownDate) {
        return YES;
    }
    const NSTimeInterval secondsSinceLastInterstitial = [[NSDate date] timeIntervalSinceDate:self.lastInterstitialVideoShownDate];
    return (secondsSinceLastInterstitial * 1000) > self.config.interstitialVideoIntervalMillis;
}

- (BOOL) shouldAllowInterstitialVideo {
    return self.config.interstitialVideoEnabled && [self hasEnoughTimePassedSinceLastInterstitialVideo];
}

/**
 *  Returns the creativeTypes that should be allowed for the given adType right now, taking into consideration the limits on interstitial video blending that may be in effect right now.
 */
- (NSSet *) creativeTypesAllowedForAdType:(HZAdType)adType {
    switch(adType){
        case HZAdTypeInterstitial:
            if([self shouldAllowInterstitialVideo])
                return [NSSet setWithArray:@[@(HZCreativeTypeVideo), @(HZCreativeTypeStatic)]];
            else
                return [NSSet setWithArray:@[@(HZCreativeTypeStatic)]];
        case HZAdTypeIncentivized:
            return [NSSet setWithArray:@[@(HZCreativeTypeIncentivized)]];
        case HZAdTypeBanner:
            return [NSSet setWithArray:@[@(HZCreativeTypeBanner)]];
        case HZAdTypeVideo:
            return [NSSet setWithArray:@[@(HZCreativeTypeVideo)]];
    }
}

@end


#pragma mark - Helper Classes

@implementation HZMediationAdapterWithCreativeTypeScore

- (instancetype) initWithAdapter:(HZBaseAdapter *)adapter creativeType:(HZCreativeType)creativeType score:(NSNumber *)score {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _creativeType = creativeType;
        _score = score;
    }
    
    return self;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"Adapter: %@ creativeType:%@ score:%@", [self.adapter name], NSStringFromCreativeType(self.creativeType), self.score];
}

@end
