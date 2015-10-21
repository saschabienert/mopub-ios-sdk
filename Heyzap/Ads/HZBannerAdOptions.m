//
//  HZBannerAdOptions.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdOptions.h"
#import "HZBannerAdOptions_Private.h"
#import "HZMediationConstants.h"
#import "HZFBAdView.h"
#import "HZGADBannerView.h"

#import "HZHZAdMobBannerSupport.h"
#import "HZAdsManager.h"

#import "HZiAdAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZFacebookAdapter.h"
#import "HZInMobiAdapter.h"

#import "HZAdModel.h"
#import "HZDevice.h"

@interface HZBannerAdOptions()

NSValue *hzAdMobBannerSizeValue(HZAdMobBannerSize size);
NSValue *hzFacebookBannerSizeValue(HZFacebookBannerSize size);

HZAdMobBannerSize hzAdMobBannerSizeFromValue(NSValue *value);
HZFacebookBannerSize hzFacebookBannerSizeFromValue(NSValue *value);

NSString *hzFacebookBannerSizeDescription(HZFacebookBannerSize size);
NSString *hzAdMobBannerSizeDescription(HZAdMobBannerSize size);

@end

// Ignore deprecation warnings to allow us to use our own HZFacebookBannerSize320x50 constant.
// TODO: Remove this after we remove HZFacebookBannerSize320x50.
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@implementation HZBannerAdOptions
@synthesize tag = _tag;

// Note: These are taken from https://support.inmobi.com/monetize/integration/monetization-server-to-server-api-integration-guides/api-2.0-integration-guidelines
// (There aren't any constants in the InMobi SDK we can get these values from)
const CGSize HZInMobiBannerSize320x50 = {320, 50};
const CGSize HZInMobiBannerSize468x60 = {468, 60};
const CGSize HZInMobiBannerSize480x75 = {480, 75};
const CGSize HZInMobiBannerSize728x90 = {728, 90};

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }
    
    return _tag;
}

- (void) setTag:(NSString *)tag {
    _tag = [HZAdModel normalizeTag:tag];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _facebookBannerSize = HZFacebookBannerSizeFlexibleWidthHeight50;
        
        const BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
        
        if (isLandscape) {
            _admobBannerSize = HZAdMobBannerSizeFlexibleWidthLandscape;
        } else {
            _admobBannerSize = HZAdMobBannerSizeFlexibleWidthPortrait;
        }
        
        
        if ([HZDevice isPhone]) {
            if (isLandscape) {
                _inMobiBannerSize = HZInMobiBannerSize468x60;
            } else {
                _inMobiBannerSize = HZInMobiBannerSize320x50;
            }
        } else {
            _inMobiBannerSize = HZInMobiBannerSize728x90;
        }
        
        _fetchTimeout = DBL_MAX;
    }
    return self;
}

- (UIViewController *)presentingViewController {
    if (_presentingViewController) {
        return _presentingViewController;
    } else {
        return [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }
}

- (HZFBAdSize)internalFacebookAdSize {
    NSString *constantName = @"kFBAdSizeHeight50Banner";
    
    switch (self.facebookBannerSize) {
        case HZFacebookBannerSize320x50: {
            constantName = @"kFBAdSize320x50";
            HZELog(@"Warning: kFBAdSize320x50 is deprecated by Facebook.");
        } break;
            
        case HZFacebookBannerSizeFlexibleWidthHeight50: {
            constantName = @"kFBAdSizeHeight50Banner";
        } break;
            
        case HZFacebookBannerSizeFlexibleWidthHeight90: {
            constantName = @"kFBAdSizeHeight90Banner";
        } break;
    }
    
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    
    if (mainBundle) {
        HZFBAdSize *adSize = CFBundleGetDataPointerForName(mainBundle, (__bridge CFStringRef)constantName);
        if (adSize) {
            return *adSize;
        }
    }

    // The approach above doesn't work on air, so we always give the hard-coded value
    if (![HZAdsManager sharedManager].isAdobeAir) {
        HZELog(@"Could not find Facebook banner size constant: %@, using hard coded value.", constantName);
    }
    
    HZFBAdSize hardcodedSize = { CGSizeMake(-1, 50) };
    return hardcodedSize;
}

- (HZGADAdSize)internalAdMobSize {
    NSString *constantName = @"kGADAdSizeBanner";
    
    switch (self.admobBannerSize) {
        case HZAdMobBannerSizeFlexibleWidthPortrait: {
            constantName = @"kGADAdSizeSmartBannerPortrait";
        } break;
            
        case HZAdMobBannerSizeFlexibleWidthLandscape: {
            constantName = @"kGADAdSizeSmartBannerLandscape";
        } break;
            
        case HZAdMobBannerSizeBanner: {
            constantName = @"kGADAdSizeBanner";
        } break;
            
        case HZAdMobBannerSizeLargeBanner: {
            constantName = @"kGADAdSizeLargeBanner";
        } break;
            
        case HZAdMobBannerSizeLeaderboard: {
            constantName = @"kGADAdSizeLeaderboard";
        } break;
            
        case HZAdMobBannerSizeFullBanner: {
            constantName = @"kGADAdSizeFullBanner";
        } break;
    }
    
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    
    if (mainBundle) {
        HZGADAdSize *adSize = CFBundleGetDataPointerForName(mainBundle, (__bridge CFStringRef)constantName);
        if (adSize) {
            return *adSize;
        }
    }
    
    // The approach above doesn't work on air, so we always give the hard-coded value
    if (![HZAdsManager sharedManager].isAdobeAir) {
        HZELog(@"Could not find AdMob banner size constant: %@, using hard coded value.", constantName);
    }
    
    HZGADAdSize hardcodedSize = { {0,0}, 18};
    return hardcodedSize;
}

+ (NSArray *)admobBannerSizes {
    return @[
             hzAdMobBannerSizeValue(HZAdMobBannerSizeFlexibleWidthPortrait), // default value should be first
             hzAdMobBannerSizeValue(HZAdMobBannerSizeFlexibleWidthLandscape),
             hzAdMobBannerSizeValue(HZAdMobBannerSizeBanner),
             hzAdMobBannerSizeValue(HZAdMobBannerSizeLargeBanner),
             hzAdMobBannerSizeValue(HZAdMobBannerSizeLeaderboard),
             hzAdMobBannerSizeValue(HZAdMobBannerSizeFullBanner),
             ];
}

+ (NSArray *)facebookBannerSizes {
    return @[
             hzFacebookBannerSizeValue(HZFacebookBannerSizeFlexibleWidthHeight50), // default value should be first
             hzFacebookBannerSizeValue(HZFacebookBannerSizeFlexibleWidthHeight90),
             hzFacebookBannerSizeValue(HZFacebookBannerSize320x50),
             ];
}

+ (NSArray *)inmobiBannerSizes {
    return @[
             [NSValue valueWithCGSize:HZInMobiBannerSize320x50],
             [NSValue valueWithCGSize:HZInMobiBannerSize468x60],
             [NSValue valueWithCGSize:HZInMobiBannerSize480x75],
             [NSValue valueWithCGSize:HZInMobiBannerSize728x90],
             ];
    
}

NSValue *hzAdMobBannerSizeValue(HZAdMobBannerSize size) {
    return [NSValue valueWithBytes:&size objCType:@encode(HZAdMobBannerSize)];
}

NSValue *hzFacebookBannerSizeValue(HZFacebookBannerSize size) {
    return [NSValue valueWithBytes:&size objCType:@encode(HZFacebookBannerSize)];
}

HZAdMobBannerSize hzAdMobBannerSizeFromValue(NSValue *value) {
    HZAdMobBannerSize size;
    [value getValue:&size];
    return size;
}

HZFacebookBannerSize hzFacebookBannerSizeFromValue(NSValue *value) {
    HZFacebookBannerSize size;
    [value getValue:&size];
    return size;
}

NSString *hzAdMobBannerSizeDescription(HZAdMobBannerSize size) {
    switch (size) {
        case HZAdMobBannerSizeFlexibleWidthPortrait: {
            return @"Flex × (50–90)";
        }
        case HZAdMobBannerSizeFlexibleWidthLandscape: {
            return @"Flex × (32–90)";
        }
        case HZAdMobBannerSizeBanner: {
            return @"320 × 50";
        }
        case HZAdMobBannerSizeLargeBanner: {
            return @"320 × 100";
        }
        case HZAdMobBannerSizeLeaderboard: {
            return @"728 × 90 (iPad)";
        }
        case HZAdMobBannerSizeFullBanner: {
            return @"468 × 60";
        }
    }
}

NSString *hzFacebookBannerSizeDescription(HZFacebookBannerSize size) {
    switch (size) {
        case HZFacebookBannerSizeFlexibleWidthHeight50: {
            return @"Flex × 50";
        }
        case HZFacebookBannerSizeFlexibleWidthHeight90: {
            return @"Flex × 90";
        }
        case HZFacebookBannerSize320x50: {
            return @"320 × 50";
        }
    }
}

NSString *hzInMobiBannerSizeDescription(CGSize size) {
    return [NSString stringWithFormat:@"%.f × %.f",size.width, size.height];
}

- (BOOL)isFlexibleWidthForNetwork:(NSString *const)networkConstant {
    if ([networkConstant isEqualToString: [HZiAdAdapter name]]) {
        return YES;
    } else if ([networkConstant isEqualToString:[HZAdMobAdapter name]]) {
        return self.admobBannerSize == HZAdMobBannerSizeFlexibleWidthPortrait
            || self.admobBannerSize == HZAdMobBannerSizeFlexibleWidthLandscape;
    } else if ([networkConstant isEqualToString: [HZFacebookAdapter name]]) {
        return self.facebookBannerSize == HZFacebookBannerSizeFlexibleWidthHeight50
            || self.facebookBannerSize == HZFacebookBannerSizeFlexibleWidthHeight90;
    } else if ([networkConstant isEqualToString:[HZInMobiAdapter name]]) {
        return NO;
    } else {
        return YES;
    }
}

- (void) setFetchTimeout:(NSTimeInterval)timeout {
    if (timeout >= 0) {
        _fetchTimeout = timeout;
    } else {
        HZELog(@"ERROR: Banner ad retry timeout must be >= 0");
    }
}

- (id)copyWithZone:(NSZone *)zone {
    HZBannerAdOptions *copy = [[HZBannerAdOptions alloc] init];
    copy.presentingViewController = self.presentingViewController;
    copy.admobBannerSize = self.admobBannerSize;
    copy.facebookBannerSize = self.facebookBannerSize;
    copy.tag = self.tag;
    copy.fetchTimeout = self.fetchTimeout;
    return copy;
}


@end
