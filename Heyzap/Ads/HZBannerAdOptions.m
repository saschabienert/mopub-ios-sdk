//
//  HZBannerAdOptions.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdOptions.h"
#import "HZMediationConstants.h"
#import "HZFBAdView.h"
#import "HZGADBannerView.h"

#import "HZHZAdMobBannerSupport.h"

@interface HZBannerAdOptions()

HZFBAdSize *hzlookupFBAdSizeConstant(NSString *constantName);
HZFBAdSize *hzFBAdSize50(void);
HZFBAdSize *hzFBAdSize90(void);
HZFBAdSize *hzFBAdSize320x50(void);

@end

@implementation HZBannerAdOptions

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
    return hzFBAdSize50() != NULL
    && hzFBAdSize90() != NULL
    && hzFBAdSize320x50 != NULL;
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
            break;
        }
        case HZFacebookBannerSizeFlexibleWidthHeight50: {
            return *hzFBAdSize50();
            break;
        }
        case HZFacebookBannerSizeFlexibleWidthHeight90: {
            return *hzFBAdSize90();
            break;
        }
    }
}

- (HZGADAdSize)internalAdMobSize {
    const BOOL isAvailable = [HZHZAdMobBannerSupport hzProxiedClassIsAvailable];
    if (!isAvailable) {
        NSString *const errorMessage = @"You need to add the `HZAdMobBannerSupport` class to your project to use AdMob banners. This class is available in the zip file that you got the Heyzap SDK from. If you're using Xcode, just drag the files into your project. If you're using Unity, add the files to the Plugins/iOS folder. (Sorry about this inconvenience; there's a technical limitation with loading AdMob's size constants that we're having trouble with http://stackoverflow.com/q/29136688/1176156)";
        NSLog(errorMessage); // NSLog as well as thrown an exception, since some developers have a hard time getting exception messages, especially in Unity
        @throw [NSException exceptionWithName:@"Missing HZAdMobBannerSupport class exception" reason:errorMessage userInfo:nil];
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


@end
