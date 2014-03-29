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

@protocol HZMediationAdapter <NSObject>


+ (instancetype)sharedInstance;

- (void)prefetch;

- (BOOL)hasAd;

- (void)showAd;

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

@end