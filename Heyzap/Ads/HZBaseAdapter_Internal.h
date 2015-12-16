//
//  HZBaseAdapter_Internal.h
//  Heyzap
//
//  Created by Monroe Ekilah on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"
#import "HZShowOptions_Private.h"
#import "HZAdapterFetchOptions.h"

/**
 *  Methods & properties that should only be used internally by HZBaseAdapter and it's subclasses are declared here.
 */
@interface HZBaseAdapter()


/**
 *  These properties exist for subclasses to use. Callers must use `lastFetchErrorForAdsWithMatchingMetadata:`, and the setters should only be called from the subclasses themselves via `setLastFetchError:forAdsWithMatchingMetadata:` and `clearLastFetchErrorForAdsWithMatchingMetadata:`.
 */
@property (nonatomic, strong, nullable) NSError *lastStaticFetchError;
@property (nonatomic, strong, nullable) NSError *lastIncentivizedFetchError;
@property (nonatomic, strong, nullable) NSError *lastVideoFetchError;


/**
 *  Subclasses should call this method when a fetch fails with an appropriate error message.
 *  Subclasses can override this method, and should if they have overridden the `lastFetchErrorForAdsWithMatchingMetadata:` method.
 */
- (void) setLastFetchError:(nullable NSError *)error forAdsWithMatchingMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;
/**
 *  Convenience method for clearing the last fetchError. Default implementation just calls `setLastFetchError:forAdsWithMatchingMetadata:` with `nil` as the error parameter. Subclasses should call this method when a fetch succeeds.
 *  Subclasses can override this method, but most likely don't need to (override `setLastFetchError:forAdsWithMatchingMetadata:` instead).
 */
- (void)clearLastFetchErrorForAdsWithMatchingMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;

/**
 *  Subclasses should implement this method to read their credentials dictionary (`self.credentials`) into properties. The default implementation of this method does nothing, so can be left unimplemented for networks like iAds that don't have credentials.
 */
- (void)loadCredentials;

- (nullable NSError *)internalInitializeSDK;

/**
 *  Show an ad. This is called by the base adapter implementation after it verifies that the requested creativeType is supported by the subclass.
 */
- (void)internalShowAdWithOptions:(nonnull HZShowOptions *)options;

/**
 *  Fetch an ad. This is called by the base adapter implementation after it verifies that the requested creativeType is supported by the subclass & that the subclass does not already have an ad for the given creativeType.
 */
- (void)internalPrefetchAdWithOptions:(nonnull HZAdapterFetchOptions *)options;

- (nullable HZBannerAdapter *)internalFetchBannerWithOptions:(nonnull HZBannerAdOptions *)options placementIDOverride:(nullable NSString *)placementIDOverride reportingDelegate:(nonnull id<HZBannerReportingDelegate>)reportingDelegate;

- (BOOL)internalHasAdWithMetadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;

#pragma mark - Demographic Information Updates

/**
 *  Subclasses should override this to receive updates about notifications.
 */
- (void)updatedLocation;

#pragma mark - Logging

/**
 *  Subclasses can implement this method if they can turn logging on in the adapted SDK. This method will only be called on subclasses if they are already initialized. The method `isLoggingEnabled` can be called in this method to see if logging is on or not. The default implementation is empty.
 */
- (void) toggleLogging;
- (BOOL) isLoggingEnabled;
@end