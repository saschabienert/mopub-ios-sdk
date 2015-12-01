//
//  HZNativeAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZMediatedNativeAdViewRegisterer.h"
#import "HZMediatedNativeAd.h"

@class HZMediatedNativeAd;

NS_ASSUME_NONNULL_BEGIN

@protocol HZNativeAdReportingDelegate <NSObject>

- (void)adapter:(HZNativeAdAdapter *)adapter hadImpressionWithEventReporter:(HZMediationEventReporter *)eventReporter;
- (void)adapter:(HZNativeAdAdapter *)adapter wasClickedWithEventReporter:(HZMediationEventReporter *)eventReporter;

@end

@interface HZNativeAdAdapter : NSObject <HZMediatedNativeAdViewRegisterer>

- (instancetype)initWithParentAdapter:(HZBaseAdapter *)parentAdapter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, weak, nullable) HZBaseAdapter *parentAdapter;
@property (nonatomic, weak, nullable) id<HZNativeAdReportingDelegate>otherDelegate;
@property (nonatomic, weak, nullable) id<HZNativeAdReportingDelegate>reportingDelegate;
@property (nonatomic, nullable) HZMediationEventReporter *eventReporter;

@property (nonatomic, readonly, getter=hasReportedImpression) BOOL reportedImpression;
@property (nonatomic, readonly, getter=hasReportedClick) BOOL reportedClick;
- (void)reportImpressionIfNecessary;
- (void)reportClickIfNecessary;


- (NSString * _Nonnull)mediatedNetwork;
- (id _Nonnull)underlyingNativeAd;
- (NSString * _Nullable)title;
- (NSString * _Nullable)body;
- (NSString * _Nullable)callToAction;
- (HZNativeAdImage * _Nullable)iconImage;

- (HZNativeAdImage * _Nullable)coverImageWithPreferredOrientation:(HZPreferredImageOrientation)preferredOrientation;

- (HZMediatedNativeAdType)adType;

- (void)wrapperView:(UIView * _Nonnull)wrapperView didMoveToWindow:(UIWindow * _Nullable)window;

- (void)beginRegisteringViews;
- (void)finishRegisteringViews;
- (UIView * _Nonnull)wrapperView;

@property (nonatomic, weak, nullable) UIViewController *presentingViewController;

#pragma mark - Facebook Configuration

/**
 *  Whether or not to show an `FBAdChoicesView` in the wrapper view. Defaults to `YES`.
 *
 *  If you set this value to `NO`, you are responsible for displaying such a view.
 *  See https://developers.facebook.com/docs/audience-network/guidelines/native-ads for Facebook's native ad requirements.
 */
@property (nonatomic) BOOL shouldShowFacebookAdChoicesView;

/**
 *  The preferred corner to place the `FBAdChoicesView`. The default value is `UIRectCornerTopRight`.
 *
 *  @note `UIRectCornerAllCorners`, or any other bitmasked value, is not supported.
 */
@property (nonatomic) UIRectCorner facebookAdChoicesViewCorner;

@end

NS_ASSUME_NONNULL_END