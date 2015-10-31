//
//  HZBaseAdapter_Internal.h
//  Heyzap
//
//  Created by Monroe Ekilah on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"

/**
 *  Methods & properties that should only be used internally by HZBaseAdapter and it's subclasses are declared here.
 */
@interface HZBaseAdapter()


/**
 *  These properties exist for subclasses to use. Other callers must use `lastFetchErrorForCreativeType:` and `clearLastFetchErrorForCreativeType:`.
 */
@property (nonatomic, strong) NSError *lastStaticFetchError;
@property (nonatomic, strong) NSError *lastIncentivizedFetchError;
@property (nonatomic, strong) NSError *lastVideoFetchError;

- (void) setLastFetchError:(NSError *)error forCreativeType:(HZCreativeType)creativeType;

/**
 *  Subclasses should implement this method to read their credentials dictionary (`self.credentials`) into properties. The default implementation of this method does nothing, so can be left unimplemented for networks like iAds that don't have credentials.
 */
- (void)loadCredentials;

- (NSError *)internalInitializeSDK;

/**
 *  Show an ad. This is called by the base adapter implementation after it verifies that the requested creativeType is supported by the subclass.
 */
- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options;

/**
 *  Fetch an ad. This is called by the base adapter implementation after it verifies that the requested creativeType is supported by the subclass & that the subclass does not already have an ad for the given creativeType.
 */
- (void)internalPrefetchForCreativeType:(HZCreativeType)creativeType options:(HZFetchOptions *)fetchOptions;

- (HZBannerAdapter *)internalFetchBannerWithOptions:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate;

- (BOOL)internalHasAdForCreativeType:(HZCreativeType)creativeType placementIDOverride:(NSString *)placementIDOverride;

/**
 *  Subclasses can implement this method if they can turn logging on in the adapted SDK. This method will only be called on subclasses if they are already initialized. The method `isLoggingEnabled` can be called in this method to see if logging is on or not. The default implementation is empty.
 */
- (void) toggleLogging;
- (BOOL) isLoggingEnabled;
@end