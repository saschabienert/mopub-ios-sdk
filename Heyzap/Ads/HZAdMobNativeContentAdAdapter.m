//
//  HZAdMobNativeContentAdAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAdMobNativeContentAdAdapter.h"
#import "HZAdMobAdapter.h"

#import "HZGADNativeContentAd.h"
#import "HZGADNativeContentAdView.h"
#import "HZGADNativeAdImage.h"
#import "HZNativeAdImage_Private.h"
#import "HZGADNativeAd.h"
#import "HZGADNativeAdDelegate.h"
#import "HZView.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface HZAdMobNativeContentAdAdapter () <HZGADNativeAdDelegate>

@property (nonatomic) HZGADNativeContentAd *ad;
@property (nonatomic) HZGADNativeContentAdView *wrapperView;

@end

@implementation HZAdMobNativeContentAdAdapter

- (instancetype)initWithContentAd:(HZGADNativeContentAd *)contentAd parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super initWithParentAdapter:parentAdapter];
    if (self) {
        _ad = contentAd;
        HZGADNativeAd *nativeAd = (HZGADNativeAd *)contentAd;
        nativeAd.delegate = self;
    }
    return self;
}

- (NSString *)mediatedNetwork {
    return [HZAdMobAdapter name];
}
- (id)underlyingNativeAd {
    return self.ad;
}
- (NSString *)title {
    return self.ad.headline;
}
- (NSString *)body {
    return self.ad.body;
}
- (NSString *)callToAction {
    return self.ad.callToAction;
}

- (HZNativeAdImage *)iconImage {
    HZGADNativeAdImage *logo = self.ad.logo;
    return [[HZNativeAdImage alloc] initWithURL:logo.imageURL width:0 height:0];
}

- (HZNativeAdImage *)coverImageWithPreferredOrientation:(__unused HZPreferredImageOrientation)preferredOrientation {
    HZGADNativeAdImage *coverImage = [self.ad.images firstObject];
    if (coverImage) {
        return [[HZNativeAdImage alloc] initWithURL:coverImage.imageURL width:0 height:0];
    } else {
        return nil;
    }
}

- (HZMediatedNativeAdType)adType {
    return HZMediatedNativeAdTypeAdMobContent;
}

- (UIView *)wrapperView {
    if (!_wrapperView) {
        _wrapperView = [[[[self class] wrapperSubclass] alloc] init];
        Ivar ivar = class_getInstanceVariable([[self class] wrapperSubclass], "_heyzapDelegate");
        NSAssert(ivar, @"The _heyzapDelegate Ivar must not be null");
        object_setIvar(_wrapperView, ivar, self);
        _wrapperView.nativeContentAd = self.underlyingNativeAd;
    }
    return (UIView *)_wrapperView;
}

- (void)wrapperView:(UIView *)wrapperView didMoveToWindow:(UIWindow *)window {
    
}

- (void)beginRegisteringViews {
    self.wrapperView.headlineView = nil;
    self.wrapperView.bodyView = nil;
    self.wrapperView.logoView = nil;
    self.wrapperView.imageView = nil;
    self.wrapperView.callToActionView = nil;
}
- (void)finishRegisteringViews {
    if (!self.wrapperView.headlineView) {
        HZELog(@"AdMob requires that the title (\"headline\") be displayed for Content ads. Please call `registerTitleView:` with the view you used.");
    }
    if (!self.wrapperView.bodyView) {
        HZELog(@"AdMob requires that the body be displayed for Content ads. Please call `registerCallToActionView:` with the view you used.");
    }
}

- (void)registerTitleView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.headlineView = view;
}
- (void)registerBodyView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.bodyView = view;
}
- (void)registerIconView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.logoView = view;
}
- (void)registerCoverImageView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.imageView = view;
}
- (void)registerCallToActionView:(UIView *)view {
    self.wrapperView.callToActionView = view;
}
- (void)registerAdvertiserNameView:(UIView *)view tappable:(BOOL)tappable {
    // Hm, should this be merged into registerTitleView?
}
- (void)registerOtherView:(UIView *)view tappable:(BOOL)tappable {
    
}
- (void)registerOtherViews:(NSArray<UIView *> *)views tappable:(BOOL)tappable {
    
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"GADNativeAdDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)nativeAdWillPresentScreen:(HZGADNativeAd *)nativeAd {
    [self reportClickIfNecessary];
}

- (void)nativeAdWillLeaveApplication:(HZGADNativeAd *)nativeAd {
    [self reportClickIfNecessary];
}

+ (Class)wrapperSubclass {
    static Class subclass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        subclass = [self wrapperViewSubclass:@"HZGADNativeContentAdViewSubclass" forSuperclass:@"GADNativeContentAdView"];
    });
    return subclass;
}

@end
