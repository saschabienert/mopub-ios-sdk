//
//  HZBaseAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 4/1/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

// This is a bitmasked parameter, but with the exception of the `supportedAdFormats` method, almost everything else should treat it as just an enum.
typedef NS_OPTIONS(NSUInteger, HZAdType) {
    HZAdTypeInterstitial = 1 << 0,
    HZAdTypeVideo = 1 << 1,
    HZAdTypeIncentivized = 1 << 2,
};

@class HZBaseAdapter;

@protocol HZMediationAdapterDelegate <NSObject>

- (void)adapterWasClicked:(HZBaseAdapter *)adapter;
- (void)adapterDidDismissAd:(HZBaseAdapter *)adapter;

- (void)adapterDidCompleteIncentivizedAd:(HZBaseAdapter *)adapter;
- (void)adapterDidFailToCompleteIncentivizedAd:(HZBaseAdapter *)adapter;

@end

@interface HZBaseAdapter : NSObject

/**
 *  Adapters should record their lastError, from e.g. delegate callbacks.
 */
@property (nonatomic, strong) NSError *lastError;

@property (nonatomic, weak) id<HZMediationAdapterDelegate>delegate;


+ (instancetype)sharedInstance;

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag;

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag;

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag;

- (HZAdType)supportedAdFormats;

+ (NSString *)name;

+ (BOOL)isSDKAvailable;

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials;

#pragma mark - Inferred methods

- (NSString *)name;

- (BOOL)supportsAdType:(HZAdType)adType;

#pragma mark - Implemented methods

+ (Class)adapterClassForName:(NSString *)adapterName;

+ (NSSet *)allAdapterClasses;

@end
