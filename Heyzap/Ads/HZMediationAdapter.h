//
//  HZMediatorProtocol.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, HZAdType) {
    HZAdTypeInterstitial = 1 << 0,
    HZAdTypeVideo = 1 << 1,
    HZAdTypeIncentivized = 1 << 2,
};

@protocol HZMediationAdapter;

@protocol HZMediationAdapterDelegate <NSObject>

- (void)adapterWasClicked:(id<HZMediationAdapter>)adapter;
- (void)adapterDidDismissAd:(id<HZMediationAdapter>)adapter;

- (void)adapterDidCompleteIncentivizedAd:(id<HZMediationAdapter>)adapter;
- (void)adapterDidFailToCompleteIncentivizedAd:(id<HZMediationAdapter>)adapter;

@end

@protocol HZMediationAdapter <NSObject>


+ (instancetype)sharedInstance;

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag;

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag;

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag;

- (HZAdType)supportedAdFormats;

+ (NSString *)name;

+ (BOOL)isSDKAvailable;

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials;

// Prefetch method needs the tag and geo (geo for chartboost).
// Or just store geo on chartboost class. That's easier.

/**
 *  Adapters should record their lastError, from e.g. delegate callbacks.
 */
@property (nonatomic, strong) NSError *lastError;

@property (nonatomic, weak) id<HZMediationAdapterDelegate>delegate;




@end