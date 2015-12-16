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
#import "HZMediationInterstitialVideoManager.h"
#import "HZMediationPersistentConfig.h"
#import "HZDispatch.h"

@interface HZMediationAvailabilityChecker()

@property (nonatomic) HZMediationInterstitialVideoManager *interstitialVideoManager;
@property (nonatomic) id<HZMediationPersistentConfigReadonly> persistentConfig;

@end


@implementation HZMediationAvailabilityChecker


#pragma mark - Init

- (instancetype)initWithInterstitialVideoManager:(HZMediationInterstitialVideoManager *)interstitialVideoManager persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig {
    self = [super init];
    if (self) {
        _interstitialVideoManager = interstitialVideoManager;
        _persistentConfig = persistentConfig;
    }
    return self;
}


#pragma mark - External Availability Checks 

- (NSOrderedSet *)availableAndAllowedAdaptersForAdType:(HZAdType)adType tag:(NSString *)tag adapters:(NSOrderedSet *)adapters segmentationController:(HZSegmentationController *)segmentationController {
    NSSet *allowedCreativeTypes = [self.interstitialVideoManager creativeTypesAllowedToShowForAdType:adType];
    
    __block NSIndexSet *indexes;
    hzEnsureMainQueue(^{
        indexes = [adapters indexesOfObjectsPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
            for(NSNumber *allowedCreativeTypeNumber in allowedCreativeTypes) {
                HZCreativeType allowedCreativeType = hzCreativeTypeFromObject(allowedCreativeTypeNumber);
                NSString *placementIDOverride = [segmentationController placementIDOverrideForAdapter:adapter tag:tag creativeType:allowedCreativeType];
                HZMediationAdAvailabilityDataProvider *metadata = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:allowedCreativeType placementIDOverride:placementIDOverride tag:tag];
                
                if([adapter supportsCreativeType:allowedCreativeType]
                   && [adapter hasCredentialsForCreativeType:allowedCreativeType]
                   && [self.persistentConfig isNetworkEnabled:[adapter name]]
                   && [segmentationController adapterHasAllowedAd:adapter withMetadata:metadata]) {
                    
                    return YES;
                }
            }
            
            return NO;
        }];
    });
    
    return [NSOrderedSet orderedSetWithArray:[adapters objectsAtIndexes:indexes]];
}


#pragma mark - Externally Called on Show

- (NSOrderedSet *)parseMediateIntoAdaptersForShow:(NSDictionary *)mediateDictionary validAdapterClasses:(NSSet *)validAdapterClasses adType:(HZAdType)adType {
    NSError *error;
    NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:mediateDictionary error:&error];
    
    NSMutableOrderedSet *chosenNetworks = [NSMutableOrderedSet orderedSet];
    
    // check what creative types the requested ad type can show right now
    NSSet<HZCreativeTypeObject *> *creativeTypesAllowed = [self.interstitialVideoManager creativeTypesAllowedToShowForAdType:adType];
    
    for (NSDictionary *network in networks) {
        NSString *networkName = network[@"network"];
        NSSet *creativeTypeStringsForNetwork = [NSSet setWithArray:network[@"creative_types"]]; // networks can have multiple creative types in the mediation response, or a separate entry per creative type. either way, they're in an array in the response.
        Class adapter = [HZBaseAdapter adapterClassForName:networkName];
        HZBaseAdapter *adapterInstance = [adapter sharedAdapter];
        
        if ([validAdapterClasses containsObject:adapter]) {
            // add each network/creativeType tuple to the return value for each creativeType in the network's response set that matches a currently-allowed creativeType, if the network is set up & it supports the creativeType
            for (HZCreativeTypeObject * creativeTypeObject in creativeTypesAllowed) {
                HZCreativeType creativeType = hzCreativeTypeFromObject(creativeTypeObject);
                
                if (hzCreativeTypeStringSetContainsCreativeType(creativeTypeStringsForNetwork, creativeType)
                    && [adapterInstance supportsCreativeType:creativeType]
                    && [adapterInstance hasCredentialsForCreativeType:creativeType]
                    && [self.persistentConfig isNetworkEnabled:[adapterInstance name]]) {
                    
                    [chosenNetworks addObject:[[HZMediationAdapterWithCreativeTypeScore alloc] initWithAdapter:adapterInstance creativeType:creativeType]];
                }
            }
        }
    }
    return chosenNetworks;
}

- (HZMediationAdapterWithCreativeTypeScore *)firstAdapterWithAdForTag:(NSString *)tag adaptersWithScores:(NSOrderedSet *)adaptersWithScores segmentationController:(HZSegmentationController *)segmentationController {
    
    __block NSUInteger idx = NSNotFound;
    hzEnsureMainQueue(^{
        idx = [adaptersWithScores indexOfObjectPassingTest:^BOOL(HZMediationAdapterWithCreativeTypeScore *adapterWithScore, NSUInteger idx, BOOL *stop) {
            NSString *placementIDOverride = [segmentationController  placementIDOverrideForAdapter:[adapterWithScore adapter] tag:tag creativeType:[adapterWithScore creativeType]];
            HZMediationAdAvailabilityDataProvider *metadata = [[HZMediationAdAvailabilityDataProvider alloc] initWithCreativeType:[adapterWithScore creativeType] placementIDOverride:placementIDOverride tag:tag];
            if([segmentationController adapterHasAllowedAd:[adapterWithScore adapter] withMetadata:metadata]) {
               return YES;
            }
            return NO;
        }];
    });
        
    if (idx != NSNotFound) {
        return adaptersWithScores[idx];
    } else {
        return nil;
    }
}


@end


#pragma mark - Helper Classes

@implementation HZMediationAdapterWithCreativeTypeScore

- (instancetype) initWithAdapter:(HZBaseAdapter *)adapter creativeType:(HZCreativeType)creativeType {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _creativeType = creativeType;
    }
    
    return self;
}

- (NSNumber *) score {
    return [self.adapter latestMediationScoreForCreativeType:self.creativeType];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"Adapter: %@ creativeType:%@ score:%@", [self.adapter name], NSStringFromCreativeType(self.creativeType), self.score];
}

@end
