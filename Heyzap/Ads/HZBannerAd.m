//
//  HZBannerAdWrapper.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAd.h"
#import "HZMediationConstants.h"
#import "HeyzapMediation.h"
#import "HZBannerAdapter.h"
#import "HZBannerAdOptions.h"
#import "HZBannerAdOptions_Private.h"
@import iAd;

@interface HZBannerAd()

@property (nonatomic, strong, readonly) HZBannerAdapter *adapter;
@property (nonatomic, copy) HZBannerAdOptions *options;

@end

@implementation HZBannerAd

#pragma mark - Constants

NSString * const kHZBannerAdDidReceiveAdNotification = @"kHZBannerAdDidReceiveAdNotification";
NSString * const kHZBannerAdDidFailToReceiveAdNotification = @"kHZBannerAdDidFailToReceiveAdNotification";
NSString * const kHZBannerAdWasClickedNotification = @"kHZBannerAdWasClickedNotification";
NSString * const kHZBannerAdWillPresentModalViewNotification = @"kHZBannerAdWillPresentModalViewNotification";
NSString * const kHZBannerAdDidDismissModalViewNotification = @"kHZBannerAdDidDismissModalViewNotification";
NSString * const kHZBannerAdWillLeaveApplicationNotification = @"kHZBannerAdWillLeaveApplicationNotification";

NSString * const kHZBannerAdNotificationTagKey = @"kHZBannerAdNotificationTagKey";
NSString * const kHZBannerAdNetworkNameKey = @"kHZBannerAdNetworkNameKey";
NSString * const kHZBannerAdNotificationErrorKey = @"kHZBannerAdNotificationErrorKey";

#pragma mark - Initialization

- (instancetype)initWithBanner:(HZBannerAdapter *)adapter options:(HZBannerAdOptions *)options {
    HZParameterAssert(adapter);
    self = [super init];
    if (self) {
        _adapter = adapter;
        _options = options;
        adapter.bannerInteractionDelegate = self;
        
        
        CGRect rect = { .origin = CGPointZero, .size =options.presentingViewController.view.frame.size };
        self.frame = rect;
        
        if ([adapter.mediatedBanner isKindOfClass:[ADBannerView class]]) {
            ADBannerView *iad = (ADBannerView *) adapter.mediatedBanner;
            const CGSize sizeThatFits = [iad sizeThatFits:self.bounds.size];
            CGRect frame = iad.frame;
            frame.size = sizeThatFits;
            iad.frame = frame;
        }
        
        [self addSubview:adapter.mediatedBanner];
        
        const CGFloat bannerHeight = CGRectGetHeight(adapter.mediatedBanner.frame);
        rect.size.height = bannerHeight;
        self.frame = rect;
        
        
        if ([self isFlexibleWidth]) { // is flex
            // Do nothing, and take width of our superview in willMoveToSuperview:
        } else {
            // If not flex, take the width of the banner.
            rect.size.width = adapter.mediatedBanner.frame.size.width;
            self.frame = rect;
        }
    }
    return self;
}

#pragma mark - Properties

- (NSString *)mediatedNetwork {
    return self.adapter.parentAdapter.name;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, mediatedNetwork: %@, mediatedBanner: %@>", NSStringFromClass([self class]), self, self.mediatedNetwork, self.mediatedBanner];
}

- (UIView *)mediatedBanner {
    return self.adapter.mediatedBanner;
}

- (BOOL)isFlexibleWidth {
    return [self.options isFlexibleWidthForNetwork:self.adapter.parentAdapter.name];
}

#pragma mark - Requesting Ads


+ (void)requestBannerWithOptions:(HZBannerAdOptions *)options
                         success:(void (^)(HZBannerAd *banner))success
                         failure:(void (^)(NSError *error))failure {
    if (!options) {
        options = [[HZBannerAdOptions alloc] init];
    }
    HZParameterAssert(success);
    
    
    [[HeyzapMediation sharedInstance] requestBannerWithOptions:options completion:^(NSError *error, HZBannerAdapter *adapter) {
        if (error && failure) {
            failure(error);
        } else if (adapter) {
            HZBannerAd *wrapper = [[HZBannerAd alloc] initWithBanner:adapter options:options];
            success(wrapper);
        }
    }];
}

+ (void)placeBannerInView:(UIView *)view
                 position:(HZBannerPosition)position
                  options:(HZBannerAdOptions *)options
                  success:(void (^)(HZBannerAd *banner))success
                  failure:(void (^)(NSError *error))failure {
    if (!view) {
        view = [[[[UIApplication sharedApplication] keyWindow] rootViewController] view];
        if (!view) {
            NSString *const errorMessage = [NSString stringWithFormat:@"No view provided to %@, and couldn't find a rootViewController. Please specify the view to place the banner in.",NSStringFromSelector(_cmd)];
            NSLog(@"%@",errorMessage);
            @throw [NSException exceptionWithName:@"NoViewForBanner" reason:errorMessage userInfo:nil];
        }
    }
    
    if (!options) {
        options = [[HZBannerAdOptions alloc] init];
    }
    
    [self requestBannerWithOptions:options success:^(HZBannerAd *wrapper) {
        switch (position) {
            case HZBannerPositionTop: {
                CGRect tmpFrame = wrapper.frame;
                
                if ([options.presentingViewController respondsToSelector:@selector(topLayoutGuide)]
                    && options.presentingViewController.view == view) {
                    tmpFrame.origin.y += options.presentingViewController.topLayoutGuide.length;
                }
                
                wrapper.frame = tmpFrame;
                [view addSubview:wrapper];
                break;
            }
            case HZBannerPositionBottom: {
                const CGFloat viewHeight = CGRectGetMaxY(view.frame);
                const CGFloat bannerHeight = wrapper.frame.size.height;
                
                if (viewHeight < bannerHeight) {
                    NSLog(@"WARNING: %@ is placing a banner in a view whose height (%f) is less than that of the banner (%f). Is your view configured correctly?",NSStringFromSelector(_cmd), viewHeight, bannerHeight);
                }
                
                CGRect tmpFrame = wrapper.frame;
                tmpFrame.origin.y = viewHeight - bannerHeight;
                
                if ([options.presentingViewController respondsToSelector:@selector(bottomLayoutGuide)]
                    && options.presentingViewController.view == view) {
                    tmpFrame.origin.y -= options.presentingViewController.bottomLayoutGuide.length;
                }
                
                wrapper.frame = tmpFrame;
                [view addSubview:wrapper];
                break;
            }
        }
        if (success) { success(wrapper); }
    } failure:^(NSError *error) {
        HZELog(@"Error loading banner! %@",error);
        if (failure) { failure(error); }
    }];
}

#pragma mark - UIView methods

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [self.adapter bannerWasAddedToView];
    
    [super willMoveToSuperview:newSuperview];
    if ([self isFlexibleWidth]) {
        CGRect frame = self.frame;
        frame.size.width = newSuperview.bounds.size.width;
        self.frame = frame;
    }
}

#pragma mark - Delegate / Notifications

- (void)postNotification:(NSString *)notification {
    [self postNotification:notification userInfo:nil];
}

- (void)postNotification:(NSString *)notification userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    mutableInfo[kHZBannerAdNotificationTagKey] = self.options.tag;
    mutableInfo[kHZBannerAdNetworkNameKey] = self.mediatedNetwork;
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:self userInfo:mutableInfo];
}

- (void)didReceiveAd {
    if ([self.delegate respondsToSelector:@selector(bannerDidReceiveAd:)]) {
        [self.delegate bannerDidReceiveAd:self];
    }
    [self postNotification:kHZBannerAdDidReceiveAdNotification];
}

- (void)didFailToReceiveAd:(NSError *)networkError {
    NSDictionary *const userInfo = networkError ? @{NSUnderlyingErrorKey: networkError} : nil;
    NSError *const error = [[NSError alloc] initWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
    
    if ([self.delegate respondsToSelector:@selector(bannerDidFailToReceiveAd:error:)]) {
        [self.delegate bannerDidFailToReceiveAd:self error:error];
    }
    
    [self postNotification:kHZBannerAdDidFailToReceiveAdNotification
                  userInfo:@{kHZBannerAdNotificationErrorKey: error}];
}

- (void)userDidClick {
    if ([self.delegate respondsToSelector:@selector(bannerWasClicked:)]) {
        [self.delegate bannerWasClicked:self];
    }
    [self postNotification:kHZBannerAdWasClickedNotification];
}

- (void)willPresentModalView {
    if ([self.delegate respondsToSelector:@selector(bannerWillPresentModalView:)]) {
        [self.delegate bannerWillPresentModalView:self];
    }
    [self postNotification:kHZBannerAdWillPresentModalViewNotification];
}

- (void)didDismissModalView {
    if ([self.delegate respondsToSelector:@selector(bannerDidDismissModalView:)]) {
        [self.delegate bannerDidDismissModalView:self];
    }
    [self postNotification:kHZBannerAdDidDismissModalViewNotification];
}

- (void)willLeaveApplication {
    if ([self.delegate respondsToSelector: @selector(bannerWillLeaveApplication:)]) {
        [self.delegate bannerWillLeaveApplication:self];
    }
    [self postNotification:kHZBannerAdWillLeaveApplicationNotification];
}

@end
