//
//  HZBannerAdaper.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBannerAd_Private.h"
#import "HZBaseAdapter.h"

@class HZMediationSession;
@class HZBaseAdapter;

@protocol HZBannerReportingDelegate <NSObject>

- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter hadImpressionForSession:(HZMediationSession *)session;
- (void)bannerAdapter:(HZBannerAdapter *)bannerAdapter wasClickedForSession:(HZMediationSession *)session;

@end

@interface HZBannerAdapter : NSObject

@property (nonatomic, weak) id<HZBannerAdWrapperReporter> bannerInteractionDelegate;

@property (nonatomic, strong) NSError *lastError;

@property (nonatomic, strong) HZMediationSession *session;
@property (nonatomic, weak) id<HZBannerReportingDelegate> bannerReportingDelegate;
@property (nonatomic, weak) HZBaseAdapter *parentAdapter;

- (UIView *)mediatedBanner;
- (BOOL)isAvailable;

/**
 *  This should be called on the adapter when the banner is added as a subview so that an impression can be reported.
 */
- (void)bannerWasAddedToView;

@end
