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
///
- (instancetype)initWithBanner:(HZBannerAdapter *)adapter options:(HZBannerAdOptions *)options {
    NSParameterAssert(adapter);
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

- (NSString *)mediatedNetwork {
    return self.adapter.parentAdapter.name;
}


+ (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAd *wrapper))completion {
    if (!options) {
        options = [[HZBannerAdOptions alloc] init];
    }
    NSParameterAssert(completion);
    
    
    [[HeyzapMediation sharedInstance] requestBannerWithOptions:options completion:^(NSError *error, HZBannerAdapter *adapter) {
        if (error) {
            completion(error, nil);
        } else if (adapter) {
            
            HZBannerAd *wrapper = [[HZBannerAd alloc] initWithBanner:adapter options:options];
            completion(nil, wrapper);
        }
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, mediatedNetwork: %@, mediatedBanner: %@>", NSStringFromClass([self class]), self, self.mediatedNetwork, self.mediatedBanner];
}

NSString * const kHZBannerAdDidReceiveAdNotification = @"kHZBannerAdDidReceiveAdNotification";
NSString * const kHZBannerAdDidFailToReceiveAdNotification = @"kHZBannerAdDidFailToReceiveAdNotification";
NSString * const kHZBannerAdWasClickedNotification = @"kHZBannerAdWasClickedNotification";
NSString * const kHZBannerAdWillPresentModalViewNotification = @"kHZBannerAdWillPresentModalViewNotification";
NSString * const kHZBannerAdDidDismissModalViewNotification = @"kHZBannerAdDidDismissModalViewNotification";
NSString * const kHZBannerAdWillLeaveApplicationNotification = @"kHZBannerAdWillLeaveApplicationNotification";

NSString * const kHZBannerAdNotificationTagKey = @"kHZBannerAdNotificationTagKey";
NSString * const kHZBannerAdNetworkNameKey = @"kHZBannerAdNetworkNameKey";
NSString * const kHZBannerAdNotificationErrorKey = @"kHZBannerAdNotificationErrorKey";

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
    [self postNotification:kHZBannerAdDidReceiveAdNotification];
    [self.delegate bannerDidReceiveAd:self];
}

- (void)didFailToReceiveAd:(NSError *)networkError {
    NSDictionary *const userInfo = networkError ? @{NSUnderlyingErrorKey: networkError} : nil;
    NSError *const error = [[NSError alloc] initWithDomain:kHZMediationDomain code:1 userInfo:userInfo];
    
    [self.delegate bannerDidFailToReceiveAd:self error:error];
    [self postNotification:kHZBannerAdDidFailToReceiveAdNotification
                  userInfo:@{kHZBannerAdNotificationErrorKey: error}];
}

- (void)userDidClick {
    [self.delegate bannerWasClicked:self];
    [self postNotification:kHZBannerAdWasClickedNotification];
}

- (void)willPresentModalView {
    [self.delegate bannerWillPresentModalView:self];
    [self postNotification:kHZBannerAdWillPresentModalViewNotification];
}

- (void)didDismissModalView {
    [self.delegate bannerDidDismissModalView:self];
    [self postNotification:kHZBannerAdDidDismissModalViewNotification];
}

- (void)willLeaveApplication {
    [self.delegate bannerWillLeaveApplication:self];
    [self postNotification:kHZBannerAdWillLeaveApplicationNotification];
}

- (UIView *)mediatedBanner {
    return self.adapter.mediatedBanner;
}

+ (void)placeBannerInView:(UIView *)view
                 position:(HZBannerPosition)position
                  options:(HZBannerAdOptions *)options
               completion:(void (^)(NSError *error, HZBannerAd *wrapper))completion {
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
    
    [self requestBannerWithOptions:options completion:^(NSError *error, HZBannerAd *wrapper) {
        if (error) {
            HZELog(@"Error loading banner! %@",error);
            if (completion) { completion(error, nil); }
        } else {
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
            if (completion) { completion(nil, wrapper); }
            
        }
    }];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if ([self isFlexibleWidth]) {
        CGRect frame = self.frame;
        frame.size.width = newSuperview.bounds.size.width;
        self.frame = frame;
    }
}

- (BOOL)isFlexibleWidth {
    return [self.options isFlexibleWidthForNetwork:self.adapter.parentAdapter.name];
}

@end
