//
//  HZVungleSDK.h
//  Heyzap
//
//  Created by David Stumm on 8/28/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HZClassProxy.h"

@protocol HZVungleSDKLogger <NSObject>
- (void)vungleSDKLog:(NSString*)message;
@end

@protocol HZVungleAssetLoader<NSObject>
- (NSData*)vungleLoadAsset:(NSString*)path;
- (UIImage*)vungleLoadImage:(NSString*)path;
@end

@protocol HZVungleSDKDelegate <NSObject>
@optional
- (void)vungleSDKwillShowAd;
- (void)vungleSDKwillCloseAdWithViewInfo:(NSDictionary*)viewInfo willPresentProductSheet:(BOOL)willPresentProductSheet;
- (void)vungleSDKwillCloseProductSheet:(id)productSheet;
- (void)vungleSDKhasCachedAdAvailable; // Deprecated in Vungle SDK 3.1.0
- (void)vungleSDKAdPlayableChanged:(BOOL)isAdPlayable;
@end

@interface HZVungleSDK : HZClassProxy
@property (strong, atomic) NSDictionary* userData;
@property (strong, atomic) id<HZVungleSDKDelegate> delegate;
@property (strong, atomic) id<HZVungleAssetLoader> assetLoader;
@property (strong, atomic) NSString* incentivizedAlertText;
@property (assign, atomic) BOOL muted;
@property (readonly, atomic) NSMutableDictionary* globalOptions;

+ (HZVungleSDK*)sharedSDK;
- (void)startWithAppId:(NSString*)appId;
- (BOOL)playAd:(UIViewController *)viewController error:(NSError **)error;
- (BOOL)playAd:(UIViewController *)viewController withOptions:(id)options error:(NSError **)error;
- (BOOL)isCachedAdAvailable; // Deprecated in Vungle SDK 3.1.0
- (BOOL)isAdPlayable;
- (NSDictionary*)debugInfo;
- (void)setLoggingEnabled:(BOOL)enable;
- (void)log:(NSString*)message, ... NS_FORMAT_FUNCTION(1,2);
- (void)attachLogger:(id<HZVungleSDKLogger>)logger;
- (void)detachLogger:(id<HZVungleSDKLogger>)logger;
- (void)clearCache;
- (void)clearSleep;
@end
