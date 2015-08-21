//
//  HZMediationAvailabilityChecker.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"

@class HZBaseAdapter;
@class HZInterstitialVideoConfig;
@protocol HZMediationPersistentConfigReadonly;

/**
 *  This class handles checking if an ad is available, keeping track of relevant state like interstitial video rate limiting.
 */
@interface HZMediationAvailabilityChecker : NSObject

- (instancetype)initWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig;

- (NSOrderedSet *)availableAdaptersForAdType:(HZAdType)adType adapters:(NSOrderedSet *)adapters;
- (HZBaseAdapter *)firstAdapterWithAdForAdType:(HZAdType)adType adapters:(NSOrderedSet *)adapters optionalForcedNetwork:(Class)forcedNetwork;


- (void)updateWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig;
- (void)didShowInterstitialVideo;

- (NSOrderedSet *)parseMediateIntoAdapters:(NSDictionary *)mediateDictionary setupAdapterClasses:(NSSet *)setupAdapterClasses adType:(HZAdType)adType;


@end
