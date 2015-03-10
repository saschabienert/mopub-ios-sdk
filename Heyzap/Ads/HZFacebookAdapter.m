//
//  HZFacebookAdapter.m
//  Heyzap
//
//  Created by David Stumm on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZFacebookAdapter.h"
#import "HZFBInterstitialAd.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZBannerAdWrapper.h"
#import "HZFBAdView.h"
#import "HZFBBannerAdapter.h"

@interface HZFacebookAdapter() <HZFBInterstitialAdDelegate>
@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, strong) HZFBInterstitialAd *interstitialAd;

HZFBAdSize *hzlookupFBAdSizeConstant(NSString *constantName);
HZFBAdSize *hzFBAdSize50(void);
HZFBAdSize *hzFBAdSize90(void);

@end

@implementation HZFacebookAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance {
    static HZFacebookAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZFacebookAdapter alloc] init];
    });
    return proxy;
}

#pragma mark - Adapter Protocol

+ (BOOL)isSDKAvailable {
    return [HZFBInterstitialAd hzProxiedClassIsAvailable]
    && [HZFBAdView hzProxiedClassIsAvailable]
    && hzFBAdSize50() != NULL
    && hzFBAdSize90() != NULL;
}

+ (NSString *)name {
    return kHZAdapterFacebook;
}

+ (NSString *) humanizedName {
    return kHZAdapterFacebookHumanized;
}

+ (NSString *)sdkVersion {
    return nil;
}

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials {
    NSParameterAssert(credentials);
    NSError *error;
    
    NSString *placementID = [HZDictionaryUtils
                             objectForKey:@"placement_id"
                             ofClass:[NSString class]
                             dict:credentials
                             error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    HZFacebookAdapter *adapter = [self sharedInstance];
    if (!adapter.credentials) {
        adapter.credentials = credentials;
        adapter.placementID = placementID;
    }
    
    return nil;
}

- (HZAdType)supportedAdFormats {
    return HZAdTypeInterstitial;
}

- (BOOL)isVideoOnlyNetwork {
    return NO;
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag {
    return type == HZAdTypeInterstitial && self.interstitialAd && self.interstitialAd.isAdValid;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag {
    
    NSAssert(self.placementID, @"Need a Placement ID by this point");
    
    if (type != HZAdTypeInterstitial) {
        // only prefetch if they want an interstitial
        return;
    }
    
    if (self.interstitialAd
        && !self.lastInterstitialError) {
        // If we have an interstitial already out fetching, don't start up a re-fetch.
        return;
    }
    
    self.interstitialAd = [[HZFBInterstitialAd alloc] initWithPlacementID:self.placementID];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAd];
}

- (void)showAdForType:(HZAdType)type options:(HZShowOptions *)options {
    if (type != HZAdTypeInterstitial) {
        //can only show interstitials
        return;
    }
    
    [self.interstitialAd showAdFromRootViewController:options.viewController];
}

#pragma mark - Facebook Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"FBInterstitialAdDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

- (void)interstitialAdDidClick:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterWasClicked:self];
}

- (void)interstitialAdDidClose:(HZFBInterstitialAd *)interstitialAd {
    [self.delegate adapterDidDismissAd:self];
    self.interstitialAd = nil;
}

- (void)interstitialAdWillClose:(HZFBInterstitialAd *)interstitialAd {
    
}

- (void)interstitialAdDidLoad:(HZFBInterstitialAd *)interstitialAd {
    self.lastInterstitialError = nil;
}

- (void)interstitialAd:(HZFBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    self.lastInterstitialError = [NSError errorWithDomain:kHZMediationDomain
                                                     code:1
                                                 userInfo:@{kHZMediatorNameKey: @"Facebook",
                                                            NSUnderlyingErrorKey: error}];
    self.interstitialAd = nil;
}

- (void)interstitialAdWillLogImpression:(HZFBInterstitialAd *)interstitialAd {
}

- (HZBannerAdapter *)fetchBannerWithRootViewController:(UIViewController *const)controller {
    HZFBAdView *view = [[HZFBAdView alloc] initWithPlacementID:@"500413400097719_538033529669039" adSize:*hzFBAdSize90() rootViewController:controller];
    
    return [[HZFBBannerAdapter alloc] initWithHZFBAdView:view];
}

HZFBAdSize *hzFBAdSize50(void) {
    return hzlookupFBAdSizeConstant(@"kFBAdSizeHeight50Banner");
}

HZFBAdSize *hzFBAdSize90(void) {
    return hzlookupFBAdSizeConstant(@"kFBAdSizeHeight90Banner");
}

HZFBAdSize *hzlookupFBAdSizeConstant(NSString *const constantName) {
    return CFBundleGetDataPointerForName(CFBundleGetMainBundle(), (__bridge CFStringRef)constantName);
}

//- (HZFBAdSize *)foo {
//    void * dataPtr = CFBundleGetDataPointerForName(CFBundleGetMainBundle(), (__bridge CFStringRef)@"kFBAdSize320x50f");
//    if (dataPtr) {
//        NSLog(@"Data ptr was present");
//    } else {
//        NSLog(@"Data ptr missing");
//        return NULL;
//    }
//    //    NSLog(@"dataPtr = %@",*dataPtr);
//    HZFBAdSize *x = dataPtr;
//    //    FBAdSize *x = (FBAdSize *)(dataPtr ? *dataPtr : nil);
//    CGSize size = x->size;
//    NSLog(@"Size = %@",NSStringFromCGSize(size));
//    
//    return x;
//}

@end
