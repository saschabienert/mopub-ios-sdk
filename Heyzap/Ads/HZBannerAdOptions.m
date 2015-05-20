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

HZFBAdSize *hzlookupFBAdSizeConstant(NSString *constantName);
HZFBAdSize *hzFBAdSize50(void);
HZFBAdSize *hzFBAdSize90(void);
HZFBAdSize *hzFBAdSize320x50(void);

NSValue *hzAdMobBannerSizeValue(HZAdMobBannerSize size);
NSValue *hzFacebookBannerSizeValue(HZFacebookBannerSize size);
HZAdMobBannerSize hzAdMobBannerSizeFromValue(NSValue *value);
HZFacebookBannerSize hzFacebookBannerSizeFromValue(NSValue *value);

NSString *hzFacebookBannerSizeDescription(HZFacebookBannerSize size);
NSString *hzAdMobBannerSizeDescription(HZAdMobBannerSize size);

@end

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
        _admobBannerSize = HZAdMobBannerSizeFlexibleWidthPortrait;
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

+ (BOOL)facebookBannerSizesAvailable {
    // Constant loading isn't available in Adobe Air for some reason
    // See `internalFacebookAdSize` for details
    if ([HZAdsManager sharedManager].isAdobeAir) {
        return YES;
    } else {
        return hzFBAdSize50() != NULL
        && hzFBAdSize90() != NULL
        && hzFBAdSize320x50() != NULL;
    }
}

HZFBAdSize *hzFBAdSize50(void) {
    return hzlookupFBAdSizeConstant(@"kFBAdSizeHeight50Banner");
}

HZFBAdSize *hzFBAdSize90(void) {
    return hzlookupFBAdSizeConstant(@"kFBAdSizeHeight90Banner");
}

HZFBAdSize *hzFBAdSize320x50(void) {
    return hzlookupFBAdSizeConstant(@"kFBAdSize320x50");
}

HZFBAdSize *hzlookupFBAdSizeConstant(NSString *const constantName) {
    return CFBundleGetDataPointerForName(CFBundleGetMainBundle(), (__bridge CFStringRef)constantName);
}

- (HZFBAdSize)internalFacebookAdSize {
    
    switch (self.facebookBannerSize) {
        case HZFacebookBannerSize320x50: {
            return *hzFBAdSize320x50();
        }
        case HZFacebookBannerSizeFlexibleWidthHeight50: {
            // Constant loading isn't working in Adobe Air for the Facebook SDK for some reason
            // For now I'm just hard-coding the values in the struct they use.
            // It would be good to investigate further but we need to get the adobe air SDK out to Ketchapp
            // (Also I imagine it being very difficult to debug this issue).
            if ([HZAdsManager sharedManager].isAdobeAir) {
                HZFBAdSize size = { CGSizeMake(-1, 50) };
                return size;
            } else {
                return *hzFBAdSize50();
            }
        }
        case HZFacebookBannerSizeFlexibleWidthHeight90: {
            return *hzFBAdSize90();
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
