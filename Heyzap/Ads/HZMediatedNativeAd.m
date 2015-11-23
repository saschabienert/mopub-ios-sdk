//
//  HZMediatedNativeAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/23/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediatedNativeAd.h"
#import "HZMediatedNativeAdViewRegisterer.h"
#import "HZNativeAdAdapter.h"
#import "HZMediatedNativeAdWrapperView.h"
#import "HZMediatedNativeAd_Private.h"

#import "HZFacebookAdapter.h"

NSString * const HZMediatedNativeAdImpressionNotification = @"HZMediatedNativeAdImpressionNotification";
NSString * const HZMediatedNativeAdClickNotification = @"HZMediatedNativeAdClickNotification";

@interface HZMediatedNativeAd() <HZNativeAdReportingDelegate>

@property (nonatomic, readonly) HZNativeAdAdapter *adapter;
@property (nonatomic) BOOL hasHadImpression;
@property (nonatomic) BOOL hasBeenClicked;

@end

@implementation HZMediatedNativeAd

- (instancetype)initWithAdapter:(HZNativeAdAdapter *)adapter tag:(NSString *)tag {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adapter.otherDelegate = self;
        _tag = tag;
    }
    return self;
}

- (void)registerViews:(void(^)(id<HZMediatedNativeAdViewRegisterer>registerer))block {
    [self.adapter beginRegisteringViews];
    block(self.adapter);
    [self.adapter finishRegisteringViews];
}

#pragma mark - Properties from adapter

- (NSString *)mediatedNetwork {
    return self.adapter.mediatedNetwork;
}
- (id)underlyingNativeAd {
    return self.adapter.underlyingNativeAd;
}
- (NSString *)title {
    return self.adapter.title;
}
- (NSString *)body {
    return self.adapter.body;
}
- (NSString *)callToAction {
    return self.adapter.callToAction;
}
- (HZNativeAdImage *)iconImage {
    return self.adapter.iconImage;
}

- (HZNativeAdImage *)coverImageWithPreferredOrientation:(HZPreferredImageOrientation)preferredOrientation {
    return [self.adapter coverImageWithPreferredOrientation:preferredOrientation];
}

- (HZMediatedNativeAdType)adType {
    return self.adapter.adType;
}

#pragma mark - Wrapper View

- (UIView *)wrapperView {
    return self.adapter.wrapperView;
}

- (UIViewController *)presentingViewController {
    return self.adapter.presentingViewController;
}

- (void)setPresentingViewController:(UIViewController *)presentingViewController {
    self.adapter.presentingViewController = presentingViewController;
}

#pragma mark - Facebook Configuration

- (BOOL)shouldShowFacebookAdChoicesView {
    return self.adapter.shouldShowFacebookAdChoicesView;
}

- (void)setShouldShowFacebookAdChoicesView:(BOOL)shouldShowFacebookAdChoicesView {
    self.adapter.shouldShowFacebookAdChoicesView = shouldShowFacebookAdChoicesView;
}

- (UIRectCorner)facebookAdChoicesViewCorner {
    return self.adapter.facebookAdChoicesViewCorner;
}

- (void)setFacebookAdChoicesViewCorner:(UIRectCorner)facebookAdChoicesViewCorner {
    self.adapter.facebookAdChoicesViewCorner = facebookAdChoicesViewCorner;
}

#pragma mark - Event Reporting

- (void)adapter:(HZNativeAdAdapter *)adapter hadImpressionWithEventReporter:(__unused HZMediationEventReporter *)eventReporter {
    self.hasHadImpression = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:HZMediatedNativeAdImpressionNotification
                                                        object:self
                                                      userInfo:@{
                                                                 HZNetworkNameUserInfoKey: [self mediatedNetwork],
                                                                 HZAdTagUserInfoKey: self.tag,
                                                                 }];
}
- (void)adapter:(HZNativeAdAdapter *)adapter wasClickedWithEventReporter:(__unused HZMediationEventReporter *)eventReporter {
    self.hasBeenClicked = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:HZMediatedNativeAdClickNotification
                                                        object:self
                                                      userInfo:@{
                                                                 HZNetworkNameUserInfoKey: [self mediatedNetwork],
                                                                 HZAdTagUserInfoKey: self.tag,
                                                                 }];
}

#pragma mark - Utility

- (NSString *)description {
    NSMutableString *mutableString = [[NSMutableString alloc] initWithString:[super description]];
    [mutableString appendFormat:@" type: %@",NSStringFromHZMediatedNativeAdType(self.adType)];
    [mutableString appendFormat:@" title: %@",self.title];
    return mutableString;
}

NSString * NSStringFromHZMediatedNativeAdType(HZMediatedNativeAdType adType) {
    switch (adType) {
        case HZMediatedNativeAdTypeAdMobAppInstall: {
            return @"AdMob App Install";
        }
        case HZMediatedNativeAdTypeAdMobContent: {
            return @"AdMob Content";
        }
        case HZMediatedNativeAdTypeFacebook: {
            return @"Facebook Audience Network";
        }
        case HZMediatedNativeAdTypeHeyzap: {
            return @"Heyzap";
        }
        case HZMediatedNativeAdTypeHeyzapCrossPromo: {
            return @"Heyzap Cross-Promo";
        }
    }
}

@end
