//
//  HZHYPRManager.h
//  Heyzap
//
//  Created by Daniel Rhodes on 5/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HYPRError;
@class HYPROffer;
@class HYPRDisplayRequest;
@class HYPROfferPresentationDelegate;

@protocol HYPROfferPresentationDelegate;

/** Failure block type used for notifying callers of failed operations */
typedef void(^HYPRFailureBlock)(HYPRError *error);

/**
 * Singleton providing app-wide configuration, expected to be initialized and configured in the application delegate
 */
@interface HZHYPRManager : HZClassProxy
@property (nonatomic, readonly) NSString *versionString;
+ (HZHYPRManager *)sharedManager;
+ (void)enableDebugLogging;
+ (void)disableAutomaticPreloading;
- (void)initializeWithDistributorId:(NSString *)distributorId propertyId:(NSString *)propertyId userId:(NSString *)userId;

/** Begin loading offers for display. This includes preloading video content.
 *
 * @discussion You only need to call this if you call +disableAutomaticPreloading before you initialize the HYPRManager.
 */
- (void)preloadContent;

/** Display a specific offer to a user.
 *
 * @discussion This is for advanced use only, and not sutable for most integrations. You should likely use -displayOfferWithTransactionId:completion: instead.
 *
 * @param offer instance of class HYPROffer to display
 * @param displayRequest the display request that supplied the offer.
 */
- (void)displayOffer:(HYPROffer *)offer forDisplayRequest:(HYPRDisplayRequest *)displayRequest;
- (void)checkInventory:(void (^) (BOOL isOfferReady))checkCallback;
- (void)displayOffer:(void (^) (BOOL completed, HYPROffer* offer))completionCallback;
@end
