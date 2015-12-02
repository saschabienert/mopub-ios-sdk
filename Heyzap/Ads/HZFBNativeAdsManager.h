//
//  HZFBNativeAdsManager.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@protocol HZFBNativeAdsManagerDelegate;
#import "HZFBNativeAd.h"

@interface HZFBNativeAdsManager : HZClassProxy

/*!
 @property
 
 @abstract The delegate
 */
@property (nonatomic, weak, nullable) id <HZFBNativeAdsManagerDelegate> delegate;

/*!
 @property
 
 @abstract Set the native ads manager caching policy. This controls which media from the native ads are cached before the native ads manager calls nativeAdsLoaded on its delegate. The default is to not block on caching.
 */
@property (nonatomic, assign) HZFBNativeAdsCachePolicy mediaCachePolicy;

/*!
 @property
 
 @abstract Number of unique native ads that can be accessed through nextNativeAd:. This is not valid until the nativeAdsLoaded: message has been sent.
 */
@property (nonatomic, assign, readonly) NSUInteger uniqueNativeAdCount;

/*!
 @property
 
 @abstract Returns YES after nativeAdsLoaded: message has been sent.
 */
@property (nonatomic, assign, getter=isValid, readonly) BOOL valid;

/*!
 @method
 
 @abstract Initialize the native ads manager.
 
 @param placementID The id of the ad placement. You can create your placement id from Facebook developers page.
 @param numAdsRequested The number of ads you would like the native ads manager to retrieve.
 */
- (nonnull instancetype)initWithPlacementID:(nonnull NSString *)placementID
                         forNumAdsRequested:(NSUInteger)numAdsRequested NS_DESIGNATED_INITIALIZER;

/*!
 @method
 
 @abstract The method that kicks off the loading of ads. It may be called again in the future to refresh the ads manually.
 */
- (void)loadAds;

/*!
 @method
 
 @abstract By default the native ads manager will refresh its ads periodically. This does not mean that any ads which are shown in the application's UI will be refreshed but simply that calling nextNativeAd: may return different ads at different times. This method disables that functionality.
 */
- (void)disableAutoRefresh;


/*!
 @property
 
 @abstract Retrieve the next native ad to be used from the batch. It is highly recommended that the caller wait until immediately before rendering the ad content to call this method to ensure the best ad for the given context is used. If more than uniqueNativeAdCount ads are requested cloned ads will be returned. Periodically the native ads manager will refresh and new ads will be returned.
 
 @return A FBNativeAd which is loaded and ready to be used.
 */
- (nullable HZFBNativeAd *)nextNativeAd;

@end
