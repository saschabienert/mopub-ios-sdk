//
//  HZHeyzapNativeAdAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapNativeAdAdapter.h"
#import "HZMediatedNativeAdWrapperView.h"
#import <StoreKit/StoreKit.h>
#import "HZCrossPromoAdapter.h"
#import "HZView.h"
#import "HZCrossPromoAdapter.h"

@interface HZHeyzapNativeAdAdapter() <HZMediatedNativeAdWrapperViewDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic) HZNativeAd *nativeAd;

@property (nonatomic) HZMediatedNativeAdWrapperView *wrapperView;

@property (nonatomic) NSTimer *impressionCheckingTimer;

@property (nonatomic) NSMutableArray *tappableViews;

@end

@implementation HZHeyzapNativeAdAdapter

#pragma mark - Initialization

- (instancetype)initWithNativeAd:(HZNativeAd *)nativeAd parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super initWithParentAdapter:parentAdapter];
    if (self) {
        _nativeAd = nativeAd;
        _tappableViews = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Native Ad Properties

- (NSString *)mediatedNetwork {
    return self.parentAdapter.name;
}
- (id)underlyingNativeAd {
    return self.nativeAd;
}
- (NSString *)title {
    return self.nativeAd.appName;
}
- (NSString *)body {
    return self.nativeAd.appDescription;
}
- (NSString *)callToAction {
    return self.nativeAd.callToAction;
}
- (HZNativeAdImage *)iconImage {
    return self.nativeAd.iconImage;
}

- (HZNativeAdImage *)coverImageWithPreferredOrientation:(HZPreferredImageOrientation)preferredOrientation {
    if (preferredOrientation == HZPreferredImageOrientationLandscape) {
        return self.nativeAd.landscapeCreative;
    } else {
        return self.nativeAd.portraitCreative;
    }
}

- (HZMediatedNativeAdType)adType {
    if (self.parentAdapter == [HZCrossPromoAdapter sharedAdapter]) {
        return HZMediatedNativeAdTypeHeyzapCrossPromo;
    } else {
        return HZMediatedNativeAdTypeHeyzap;
    }
}

#pragma mark - Wrapper View

- (UIView *)wrapperView {
    if (!_wrapperView) {
        _wrapperView = [[HZMediatedNativeAdWrapperView alloc] initWithFrame:CGRectZero delegate:self];
    }
    return _wrapperView;
}

- (void)wrapperView:(UIView *)wrapperView didMoveToWindow:(UIWindow *)window {
    if (!window) {
        [self.impressionCheckingTimer invalidate];
        self.impressionCheckingTimer = nil;
        [self.tappableViews removeAllObjects];
    } else if (!self.hasReportedImpression) {
        self.impressionCheckingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                        target:self
                                                                      selector:@selector(checkVisibility:)
                                                                      userInfo:nil
                                                                       repeats:YES];
    }
}

- (void)checkVisibility:(NSTimer *)timer {
    if ([HZView isViewVisible:self.wrapperView]) {
        [self reportImpressionIfNecessary];
        [self.nativeAd reportImpression];
        [timer invalidate];
        self.impressionCheckingTimer = nil;
    }
}

- (void)wrapperView:(UIView *)wrapperView wasTapped:(UIGestureRecognizer *)gestureRecognizer {
    const CGPoint tappedPoint = [gestureRecognizer locationInView:wrapperView];
    
    for (UIView *tappableView in self.tappableViews) {
        const CGRect locationInWrapper = [tappableView convertRect:tappableView.bounds toView:wrapperView];
        if (CGRectContainsPoint(locationInWrapper, tappedPoint)) {
            [self reportClickIfNecessary];

            [self.nativeAd presentAppStoreFromViewController:self.presentingViewController
                                               storeDelegate:self
                                                  completion:^(BOOL result, NSError *error) {
                                                      if (error) {
                                                          HZELog(@"Error presenting SKStoreProductViewController for native ad: %@",error);
                                                      }
                                                  }];
            break;
        }
        
    }
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - View Registration

- (void)beginRegisteringViews {
    [self.tappableViews removeAllObjects];
}
- (void)finishRegisteringViews {
    
}
- (void)registerTitleView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObject:view]; }
}
- (void)registerBodyView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObject:view]; }
}
- (void)registerIconView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObject:view]; }
}
- (void)registerCoverImageView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObject:view]; }
}
- (void)registerCallToActionView:(UIView *)view {
    [self.tappableViews addObject:view];
}
- (void)registerAdvertiserNameView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObject:view]; }
}
- (void)registerOtherView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObject:view]; }
}
- (void)registerOtherViews:(NSArray <UIView *>*)views tappable:(BOOL)tappable {
    if (tappable) { [self.tappableViews addObjectsFromArray:views]; }
}

@end
