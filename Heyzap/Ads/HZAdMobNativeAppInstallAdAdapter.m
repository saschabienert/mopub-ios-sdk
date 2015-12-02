//
//  HZAdMobNativeAppInstallAdAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZAdMobNativeAppInstallAdAdapter.h"
#import "HZGADNativeAppInstallAd.h"
#import "HZAdMobAdapter.h"
#import "HZNativeAdImage_Private.h"
#import "HZGADNativeAdImage.h"
#import "HZGADNativeAppInstallAdView.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface HZAdMobNativeAppInstallAdAdapter()

@property (nonatomic) HZGADNativeAppInstallAd *ad;
@property (nonatomic) HZGADNativeAppInstallAdView *wrapperView;

@end

@implementation HZAdMobNativeAppInstallAdAdapter

#pragma mark - Initialization

- (instancetype)initWithAppInstallAd:(HZGADNativeAppInstallAd *)appInstallAd parentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super initWithParentAdapter:parentAdapter];
    if (self) {
        _ad = appInstallAd;
    }
    return self;
}

#pragma mark - Native Ad Properties

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
    HZGADNativeAdImage *icon = self.ad.icon;
    
    return [[HZNativeAdImage alloc] initWithURL:icon.imageURL width:0 height:0];
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
    return HZMediatedNativeAdTypeAdMobAppInstall;
}

#pragma mark - Wrapper View

- (UIView *)wrapperView {
    if (!_wrapperView) {
        _wrapperView = [[[[self class] wrapperSubclass] alloc] init];
        Ivar ivar = class_getInstanceVariable([[self class] wrapperSubclass], "_heyzapDelegate");
        NSAssert(ivar, @"The _heyzapDelegate Ivar must not be null");
        object_setIvar(_wrapperView, ivar, self);
        _wrapperView.nativeAppInstallAd = self.underlyingNativeAd;
    }
    return (UIView *)_wrapperView;
}

- (void)wrapperView:(UIView *)wrapperView didMoveToWindow:(UIWindow *)window {
    
}

#pragma mark - View Registration

- (void)beginRegisteringViews {
    self.wrapperView.headlineView = nil;
    self.wrapperView.bodyView = nil;
    self.wrapperView.iconView = nil;
    self.wrapperView.imageView = nil;
    self.wrapperView.callToActionView = nil;
}
- (void)finishRegisteringViews {
    if (!self.wrapperView.headlineView) {
        HZELog(@"AdMob requires that the title (\"headline\") be displayed for App Install ads. Please call `registerTitleView:` with the view you used.");
    }
    if (!self.wrapperView.callToActionView) {
        HZELog(@"AdMob requires that the call to action be displayed for App Install ads. Please call `registerCallToActionView:` with the view you used.");
    }
    if (!self.wrapperView.iconView) {
        HZELog(@"AdMob requires that the icon be displayed for App Install ads. Please call `registerCallToActionView:` with the view you used.");
    }
}

- (void)registerTitleView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.headlineView = view;
}
- (void)registerBodyView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.bodyView = view;
}
- (void)registerIconView:(UIView *)view tappable:(BOOL)tappable {
    self.wrapperView.iconView = view;
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

#pragma mark - Util

+ (Class)wrapperSubclass {
    static Class subclass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        subclass = [self wrapperViewSubclass:@"HZGADNativeAppInstallAdViewSubclass" forSuperclass:@"GADNativeAppInstallAdView"];
    });
    return subclass;
}

@end
