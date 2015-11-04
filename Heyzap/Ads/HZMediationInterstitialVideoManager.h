//
//  HZMediationInterstitialVideoManager.h
//  Heyzap
//
//  Created by Maximilian Tagher on 7/30/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"
#import "HZCreativeType.h"

@interface HZMediationInterstitialVideoManager : NSObject

extern NSString * const kHZInterstitialVideoIntervalKey;
extern NSString * const kHZInterstitialVideoEnabledKey;

@property (nonatomic, readonly) double interstitialVideoIntervalMillis;
@property (nonatomic, readonly) BOOL interstitialVideoEnabled;

- (instancetype) initWithDictionary:(NSDictionary *)dictionary;
- (void) updateWithDictionary:(NSDictionary *)dictionary;

- (void) didShowInterstitialVideo;

- (BOOL) shouldAllowInterstitialVideo;
/**
 *  Returns a set of the creativeTypes that should be allowed to show for the given adType right now, taking into consideration the limits on interstitial video blending that may be in effect.
 */
- (NSSet <NSNumber *> *) creativeTypesAllowedToShowForAdType:(HZAdType)adType;

@end
