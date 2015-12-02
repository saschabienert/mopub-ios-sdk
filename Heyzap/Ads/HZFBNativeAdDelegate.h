//
//  HZFBNativeAdDelegate.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HZFBNativeAdDelegate <NSObject>

@optional

/*!
 @method
 
 @abstract
 Sent when an FBNativeAd has been successfully loaded.
 
 @param nativeAd An FBNativeAd object sending the message.
 */
- (void)nativeAdDidLoad:(nonnull HZFBNativeAd *)nativeAd;

/*!
 @method
 
 @abstract
 Sent immediately before the impression of an FBNativeAd object will be logged.
 
 @param nativeAd An FBNativeAd object sending the message.
 */
- (void)nativeAdWillLogImpression:(nonnull HZFBNativeAd *)nativeAd;

/*!
 @method
 
 @abstract
 Sent when an FBNativeAd is failed to load.
 
 @param nativeAd An FBNativeAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)nativeAd:(nonnull HZFBNativeAd *)nativeAd didFailWithError:(nonnull NSError *)error;

/*!
 @method
 
 @abstract
 Sent after an ad has been clicked by the person.
 
 @param nativeAd An FBNativeAd object sending the message.
 */
- (void)nativeAdDidClick:(nonnull HZFBNativeAd *)nativeAd;

/*!
 @method
 
 @abstract
 When an ad is clicked, the modal view will be presented. And when the user finishes the
 interaction with the modal view and dismiss it, this message will be sent, returning control
 to the application.
 
 @param nativeAd An FBNativeAd object sending the message.
 */
- (void)nativeAdDidFinishHandlingClick:(nonnull HZFBNativeAd *)nativeAd;

@end
