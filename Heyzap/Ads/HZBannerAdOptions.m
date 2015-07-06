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

@interface HZBannerAdOptions()

NSValue *hzAdMobBannerSizeValue(HZAdMobBannerSize size);
NSValue *hzFacebookBannerSizeValue(HZFacebookBannerSize size);
NSValue *hzHeyzapExchangeBannerSizeValue(HZHeyzapExchangeBannerSize size);

HZAdMobBannerSize hzAdMobBannerSizeFromValue(NSValue *value);
HZFacebookBannerSize hzFacebookBannerSizeFromValue(NSValue *value);
HZHeyzapExchangeBannerSize hzHeyzapExchangeBannerSizeFromValue(NSValue *value);

NSString *hzFacebookBannerSizeDescription(HZFacebookBannerSize size);
NSString *hzAdMobBannerSizeDescription(HZAdMobBannerSize size);
NSString *hzHeyzapExchangeBannerSizeDescription(HZHeyzapExchangeBannerSize size);

@end

// Ignore deprecation warnings to allow us to use our own HZFacebookBannerSize320x50 constant.
// TODO: Remove this after we remove HZFacebookBannerSize320x50.
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@implementation HZBannerAdOptions

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }
    
    return _tag;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _facebookBannerSize = HZFacebookBannerSizeFlexibleWidthHeight50;
        
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            _admobBannerSize = HZAdMobBannerSizeFlexibleWidthLandscape;
        } else {
            _admobBannerSize = HZAdMobBannerSizeFlexibleWidthPortrait;
        }
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
    switch (self.facebookBannerSize) {
        case HZFacebookBannerSize320x50: {
            return (HZFBAdSize) { CGSizeMake(320, 50) };
        }
        case HZFacebookBannerSizeFlexibleWidthHeight50: {
            return (HZFBAdSize) { CGSizeMake(-1, 50) };
        }
        case HZFacebookBannerSizeFlexibleWidthHeight90: {
            return (HZFBAdSize) { CGSizeMake(-1, 90) };
        }
    }
}

- (HZGADAdSize)internalAdMobSize {
    const BOOL isAvailable = [HZHZAdMobBannerSupport hzProxiedClassIsAvailable];
    if (!isAvailable) {
        if ([HZAdsManager sharedManager].isAdobeAir) {
            HZGADAdSize hardcodedSize = { {0,0}, 18};
            return hardcodedSize;
        } else {
            NSString *const errorMessage = @"You need to add the `HZAdMobBannerSupport` class to your project to use AdMob banners. This class is available in the zip file that you got the Heyzap SDK from. If you're using Xcode, just drag the files into your project. If you're using Unity, add the files to the Plugins/iOS folder. (Sorry about this inconvenience; there's a technical limitation with loading AdMob's size constants that we're having trouble with http://stackoverflow.com/q/29136688/1176156)";
            NSLog(errorMessage); // NSLog as well as thrown an exception, since some developers have a hard time getting exception messages, especially in Unity
            @throw [NSException exceptionWithName:@"Missing HZAdMobBannerSupport class exception" reason:errorMessage userInfo:nil];
        }
    }
    
    switch (self.admobBannerSize) {
        case HZAdMobBannerSizeFlexibleWidthPortrait: {
            return [HZHZAdMobBannerSupport adSizeNamed:@"kGADAdSizeSmartBannerPortrait"];
        }
        case HZAdMobBannerSizeFlexibleWidthLandscape: {
            return [HZHZAdMobBannerSupport adSizeNamed:@"kGADAdSizeSmartBannerLandscape"];
        }
        case HZAdMobBannerSizeBanner: {
            return [HZHZAdMobBannerSupport adSizeNamed:@"kGADAdSizeBanner"];
        }
        case HZAdMobBannerSizeLargeBanner: {
            return [HZHZAdMobBannerSupport adSizeNamed:@"kGADAdSizeLargeBanner"];
        }
        case HZAdMobBannerSizeLeaderboard: {
            return [HZHZAdMobBannerSupport adSizeNamed:@"kGADAdSizeLeaderboard"];
        }
        case HZAdMobBannerSizeFullBanner: {
            return [HZHZAdMobBannerSupport adSizeNamed:@"kGADAdSizeFullBanner"];
        }
    }
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

+ (NSArray *)heyzapExchangeBannerSizes {
    return @[
             hzHeyzapExchangeBannerSizeValue(HZHeyzapExchangeBannerSizeFlexibleWidthHeight50), // default value should be first
             hzHeyzapExchangeBannerSizeValue(HZHeyzapExchangeBannerSizeFlexibleWidthHeight90),
             ];
}

NSValue *hzAdMobBannerSizeValue(HZAdMobBannerSize size) {
    return [NSValue valueWithBytes:&size objCType:@encode(HZAdMobBannerSize)];
}

NSValue *hzFacebookBannerSizeValue(HZFacebookBannerSize size) {
    return [NSValue valueWithBytes:&size objCType:@encode(HZFacebookBannerSize)];
}

NSValue *hzHeyzapExchangeBannerSizeValue(HZHeyzapExchangeBannerSize size) {
    return [NSValue valueWithBytes:&size objCType:@encode(HZHeyzapExchangeBannerSize)];
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

HZHeyzapExchangeBannerSize hzHeyzapExchangeBannerSizeFromValue(NSValue *value) {
    HZHeyzapExchangeBannerSize size;
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
            break;
        }
        case HZFacebookBannerSizeFlexibleWidthHeight90: {
            return @"Flex × 90";
            break;
        }
        case HZFacebookBannerSize320x50: {
            return @"320 × 50";
            break;
        }
    }
}

NSString *hzHeyzapExchangeBannerSizeDescription(HZHeyzapExchangeBannerSize size) {
    switch (size) {
        case HZHeyzapExchangeBannerSizeFlexibleWidthHeight50: {
            return @"Flex × 50";
            break;
        }
        case HZHeyzapExchangeBannerSizeFlexibleWidthHeight90: {
            return @"Flex × 90";
            break;
        }
    }
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
    } else {
        return YES;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    HZBannerAdOptions *copy = [[HZBannerAdOptions alloc] init];
    copy.presentingViewController = self.presentingViewController;
    copy.admobBannerSize = self.admobBannerSize;
    copy.facebookBannerSize = self.facebookBannerSize;
    copy.tag = self.tag;
    return copy;
}


@end
