//
//  HZNativeAdAdapter.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZNativeAdAdapter.h"
#import "HZMediatedNativeAdViewRegisterer.h"

@interface HZNativeAdAdapter()

@property (nonatomic, getter=hasReportedImpression) BOOL reportedImpression;
@property (nonatomic, getter=hasReportedClick) BOOL reportedClick;

@end

@implementation HZNativeAdAdapter

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:[NSString stringWithFormat:@"Subclasses should override this method: %@", NSStringFromSelector(_cmd)] userInfo:nil];

#pragma mark - Abstract Methods

- (NSString *)mediatedNetwork {
    ABSTRACT_METHOD_ERROR()
}
- (id)underlyingNativeAd {
    ABSTRACT_METHOD_ERROR()
}
- (NSString *)title {
    ABSTRACT_METHOD_ERROR()
}
- (NSString *)body {
    ABSTRACT_METHOD_ERROR()
}
- (NSString *)callToAction {
    ABSTRACT_METHOD_ERROR()
}

- (HZNativeAdImage *)iconImage {
    ABSTRACT_METHOD_ERROR()
}

- (HZNativeAdImage *)coverImageWithPreferredOrientation:(HZPreferredImageOrientation)preferredOrientation {
    ABSTRACT_METHOD_ERROR()
}

- (HZMediatedNativeAdType)adType {
    ABSTRACT_METHOD_ERROR()
}

- (UIView *)wrapperView {
    ABSTRACT_METHOD_ERROR()
}

- (void)wrapperView:(UIView *)wrapperView didMoveToWindow:(UIWindow *)window {
    ABSTRACT_METHOD_ERROR()
}

- (void)beginRegisteringViews {
    ABSTRACT_METHOD_ERROR()
}
- (void)finishRegisteringViews {
    ABSTRACT_METHOD_ERROR()
}

- (void)registerTitleView:(UIView *)view tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}
- (void)registerBodyView:(UIView *)view tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}
- (void)registerIconView:(UIView *)view tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}
- (void)registerCoverImageView:(UIView *)view tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}
- (void)registerCallToActionView:(UIView *)view {
    ABSTRACT_METHOD_ERROR()
}
- (void)registerAdvertiserNameView:(UIView *)view tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}

- (void)registerOtherView:(UIView *)view tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}

- (void)registerOtherViews:(NSArray<UIView *> *)views tappable:(BOOL)tappable {
    ABSTRACT_METHOD_ERROR()
}

#pragma mark - Implemented Methods

- (instancetype)initWithParentAdapter:(HZBaseAdapter *)parentAdapter {
    self = [super init];
    if (self) {
        _parentAdapter = parentAdapter;
        _shouldShowFacebookAdChoicesView = YES;
        _facebookAdChoicesViewCorner = UIRectCornerTopRight;
    }
    return self;
}

- (instancetype)init NS_UNAVAILABLE {
    return nil;
}

- (void)reportImpressionIfNecessary {
    if (!self.hasReportedImpression) {
        self.reportedImpression = YES;
        [self.reportingDelegate adapter:self hadImpressionWithEventReporter:self.eventReporter];
        [self.otherDelegate adapter:self hadImpressionWithEventReporter:self.eventReporter];
    }
}

- (void)reportClickIfNecessary {
    // In case impression reporting failed somehow
    [self reportImpressionIfNecessary];
    
    if (!self.hasReportedClick) {
        self.reportedClick = YES;
        [self.reportingDelegate adapter:self wasClickedWithEventReporter:self.eventReporter];
        [self.otherDelegate adapter:self wasClickedWithEventReporter:self.eventReporter];
    }
}

- (UIViewController *)presentingViewController {
    if (!_presentingViewController) {
        HZELog(@"The presentingViewController property has not been set for this native ad. This is likely to break handling clicks for your native ad.");
    }
    return _presentingViewController;
}

@end
