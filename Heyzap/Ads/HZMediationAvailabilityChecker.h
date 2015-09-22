//
//  HZMediationAvailabilityChecker.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"
#import "HZCreativeType.h"

@class HZBaseAdapter;
@class HZBannerAdapter;
@class HZSegmentationController;
@class HZInterstitialVideoConfig;
@class HZMediationAdapterWithCreativeTypeScore;
@protocol HZMediationPersistentConfigReadonly;

/**
 *  This class handles checking if an ad is available, keeping track of relevant state like interstitial video rate limiting.
 */
@interface HZMediationAvailabilityChecker : NSObject

- (instancetype)initWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig persistentConfig:(id<HZMediationPersistentConfigReadonly>)persistentConfig;

- (NSOrderedSet *)availableAndAllowedAdaptersForAdType:(HZAdType)adType tag:(NSString *)tag adapters:(NSOrderedSet *)adapters segmentationController:(HZSegmentationController *)segmentationController;
- (HZMediationAdapterWithCreativeTypeScore *)firstAdapterWithAdForTag:(NSString *)tag adaptersWithScores:(NSOrderedSet *)adaptersWithScores optionalForcedNetwork:(Class)forcedNetwork segmentationController:(HZSegmentationController *)segmentationController;


- (void)updateWithInterstitialVideoConfig:(HZInterstitialVideoConfig *)interstitialVideoConfig;
- (void)didShowInterstitialVideo;

- (NSOrderedSet *)parseMediateIntoAdaptersForShow:(NSDictionary *)mediateDictionary setupAdapterClasses:(NSSet *)setupAdapterClasses adType:(HZAdType)adType;

@end


@interface HZMediationAdapterWithCreativeTypeScore : NSObject
@property (nonatomic) HZBaseAdapter *adapter;
@property (nonatomic) HZCreativeType creativeType;
@property (nonatomic) NSNumber *score;

@property (nonatomic) HZBannerAdapter *bannerAdapter; // used for banners only

- (instancetype) initWithAdapter:(HZBaseAdapter *)adapter creativeType:(HZCreativeType)creativeType score:(NSNumber *)score;
@end
