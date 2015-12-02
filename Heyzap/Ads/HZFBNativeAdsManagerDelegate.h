//
//  HZFBNativeAdsManagerDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HZFBNativeAdsManagerDelegate <NSObject>

/*!
 @method
 
 @abstract When the FBNativeAdsManager has finished loading a batch of ads this message will be sent. A batch of ads may be loaded in response to calling loadAds or due to an automatic refresh by the FBNativeAdsManager. At the point this message is fired all of the native ads will already be loaded and will not hence send their own nativeAdLoad: or nativeAd:didFailWithError: message.
 
 */
- (void)nativeAdsLoaded;

/*!
 @method
 
 @abstract When the FBNativeAdsManager has reached a failure while attempting to load a batch of ads this message will be sent to the application.
 @param error An NSError object with information about the failure.
 */
- (void)nativeAdsFailedToLoadWithError:(nonnull NSError *)error;

@end
