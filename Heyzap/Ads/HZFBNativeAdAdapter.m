//
//  HZFBNativeAdAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZFBNativeAdAdapter.h"
#import "HZFacebookAdapter.h"
#import "HZFBNativeAd.h"
#import "HZNativeAdImage_Private.h"
#import "HZFBAdImage.h"
#import "HZFacebookMediatedNativeAdWrapperView.h"
#import "HZFBNativeAdDelegate.h"

@interface HZFBNativeAdAdapter() <HZFacebookMediatedNativeAdWrapperViewDelegate, HZFBNativeAdDelegate>

@property (nonatomic) HZFBNativeAd *nativeAd;

@property (nonatomic) NSMutableArray <UIView *> *registeredViews;

@property (nonatomic) HZNativeAdImage *iconImage;

@property (nonatomic) HZMediatedNativeAdWrapperView *wrapperView;

@end

@implementation HZFBNativeAdAdapter

- (instancetype)initWithNativeAd:(HZFBNativeAd *)nativeAd parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super initWithParentAdapter:parentAdapter];
    if (self) {
        _nativeAd = nativeAd;
        _nativeAd.delegate = self;
        _registeredViews = [NSMutableArray array];
    }
    return self;
}

- (NSString *)mediatedNetwork {
    return [HZFacebookAdapter name];
}
- (id)underlyingNativeAd {
    return self.nativeAd;
}
- (NSString *)title {
    return self.nativeAd.title;
}
- (NSString *)body {
    return self.nativeAd.body;
}
- (NSString *)callToAction {
    return self.nativeAd.callToAction;
}
- (HZNativeAdImage *)iconImage {
    if (!_iconImage) {
        HZFBAdImage *const icon = self.nativeAd.icon;
        _iconImage = [[HZNativeAdImage alloc] initWithURL:icon.url width:icon.width height:icon.height];
    }
    return _iconImage;
}

- (HZNativeAdImage *)coverImageWithPreferredOrientation:(__unused HZPreferredImageOrientation)preferredOrientation {
    HZFBAdImage *coverImage = self.nativeAd.coverImage;
    if (coverImage) {
        return [[HZNativeAdImage alloc] initWithURL:coverImage.url width:coverImage.width height:coverImage.height];
    } else {
        return nil;
    }
}

- (HZMediatedNativeAdType)adType {
    return HZMediatedNativeAdTypeFacebook;
}

- (BOOL)shouldShowAdChoicesView {
    return self.shouldShowFacebookAdChoicesView;
}

- (UIRectCorner)adChoicesViewCorner {
    return self.facebookAdChoicesViewCorner;
}

- (UIView *)wrapperView {
    if (!_wrapperView) {
        _wrapperView = [[HZFacebookMediatedNativeAdWrapperView alloc] initWithFrame:CGRectZero delegate:self];
    }
    return _wrapperView;
}

- (void)wrapperView:(UIView *)wrapperView didMoveToWindow:(UIWindow *)window {
    if (!window) {
        [self.nativeAd unregisterView];
        [self.registeredViews removeAllObjects];
    }
}

- (void)wrapperView:(UIView *)wrapperView wasTapped:(UIGestureRecognizer *)gestureRecognizer {
    
}

- (void)beginRegisteringViews {
    [self.registeredViews removeAllObjects];
}
- (void)finishRegisteringViews {
    [self.nativeAd registerViewForInteraction:self.wrapperView
                           withViewController:self.presentingViewController
                           withClickableViews:[self.registeredViews copy]];
}

- (void)registerTitleView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObject:view];
    }
}
- (void)registerBodyView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObject:view];
    }
}
- (void)registerIconView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObject:view];
    }
}
- (void)registerCoverImageView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObject:view];
    }
}
- (void)registerCallToActionView:(UIView *)view {
    [self.registeredViews addObject:view];
}
- (void)registerAdvertiserNameView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObject:view];
    }
}
- (void)registerOtherView:(UIView *)view tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObject:view];
    }
}
- (void)registerOtherViews:(NSArray <UIView *>*)views tappable:(BOOL)tappable {
    if (tappable) {
        [self.registeredViews addObjectsFromArray:views];
    }
}

- (void)nativeAdDidLoad:(nonnull HZFBNativeAd *)nativeAd {
    
}

- (void)nativeAdWillLogImpression:(nonnull HZFBNativeAd *)nativeAd {
    [self reportImpressionIfNecessary];
}

- (void)nativeAd:(nonnull HZFBNativeAd *)nativeAd didFailWithError:(nonnull NSError *)error {
    
}

- (void)nativeAdDidClick:(nonnull HZFBNativeAd *)nativeAd {
    [self reportClickIfNecessary];
}

/*!
 @method
 
 @abstract
 When an ad is clicked, the modal view will be presented. And when the user finishes the
 interaction with the modal view and dismiss it, this message will be sent, returning control
 to the application.
 
 @param nativeAd An FBNativeAd object sending the message.
 */
- (void)nativeAdDidFinishHandlingClick:(nonnull HZFBNativeAd *)nativeAd {
 
}
@end


