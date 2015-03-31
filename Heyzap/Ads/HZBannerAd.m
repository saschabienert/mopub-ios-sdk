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

@interface HZBannerAd()

@property (nonatomic, strong, readonly) HZBannerAdapter *adapter;

@end

static NSMutableArray *allWrappers;

@implementation HZBannerAd

+ (void)initialize {
    if (self == [HZBannerAd class]) {
        allWrappers = [NSMutableArray array];
    }
}

///
- (instancetype)initWithBanner:(HZBannerAdapter *)adapter {
    NSParameterAssert(adapter);
    self = [super init];
    if (self) {
        _adapter = adapter;
        adapter.bannerInteractionDelegate = self;
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
            HZBannerAd *wrapper = [[HZBannerAd alloc] initWithBanner:adapter];
            [allWrappers addObject:wrapper];
            completion(nil, wrapper);
        }
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, mediatedNetwork: %@, mediatedBanner: %@>", NSStringFromClass([self class]), self, self.mediatedNetwork, self.mediatedBanner];
}


- (void)didReceiveAd {
    [self.delegate bannerDidReceiveAd];
}

- (void)didFailToReceiveAd:(NSError *)error {
    NSDictionary *const userInfo = error ? @{NSUnderlyingErrorKey: error} : nil;
    return [self.delegate bannerDidFailToReceiveAd:[[NSError alloc] initWithDomain:kHZMediationDomain code:1 userInfo:userInfo]];
}

- (void)userDidClick {
    [self.delegate bannerWasClicked];
}

- (void)willPresentModalView {
    [self.delegate bannerWillPresentModalView];
}

- (void)didDismissModalView {
    [self.delegate bannerDidDismissModalView];
}

- (void)willLeaveApplication {
    [self.delegate bannerWillLeaveApplication];
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
            NSLog(@"Error loading banner! %@",error);
            if (completion) { completion(error, nil); }
        } else {
            switch (position) {
                case HZBannerPositionTop: {
                    CGRect tmpFrame = wrapper.mediatedBanner.frame;
                    
                    if ([options.presentingViewController respondsToSelector:@selector(topLayoutGuide)]
                        && options.presentingViewController.view == view) {
                        tmpFrame.origin.y += options.presentingViewController.topLayoutGuide.length;
                    }
                    
                    wrapper.mediatedBanner.frame = tmpFrame;
                    [view addSubview:wrapper.mediatedBanner];
                    break;
                }
                case HZBannerPositionBottom: {
                    const CGFloat viewHeight = CGRectGetMaxY(view.frame);
                    const CGFloat bannerHeight = wrapper.mediatedBanner.frame.size.height;
                    
                    if (viewHeight < bannerHeight) {
                        NSLog(@"WARNING: %@ is placing a banner in a view whose height (%f) is less than that of the banner (%f). Is your view configured correctly?",NSStringFromSelector(_cmd), viewHeight, bannerHeight);
                    }
                    
                    CGRect tmpFrame = wrapper.mediatedBanner.frame;
                    tmpFrame.origin.y = viewHeight - bannerHeight;
                    
                    if ([options.presentingViewController respondsToSelector:@selector(bottomLayoutGuide)]
                        && options.presentingViewController.view == view) {
                        tmpFrame.origin.y -= options.presentingViewController.bottomLayoutGuide.length;
                    }
                    
                    wrapper.mediatedBanner.frame = tmpFrame;
                    [view addSubview:wrapper.mediatedBanner];
                    break;
                }
            }
            if (completion) { completion(nil, wrapper); }
            
        }
    }];
}

- (CGFloat)adHeight {
    UIView *view = (UIView *) self.mediatedBanner;
    return view.frame.size.height;
}

- (void)finishUsingBanner {
    [self.mediatedBanner removeFromSuperview];
    [allWrappers removeObjectIdenticalTo:self];
}

@end
