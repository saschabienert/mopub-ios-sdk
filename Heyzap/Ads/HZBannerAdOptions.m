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
        _facebookBannerSize = HZFacebookBannerSizeHeight50FlexibleWidth;
        _admobBannerSize = HZAdMobBannerSizeFlexibleWidthPortrait;
    }
    return self;
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
        case HZFacebookBannerSizeHeight50FlexibleWidth: {
            return *hzFBAdSize50();
            break;
        }
        case HZFacebookBannerSizeHeight90FlexibleWidth: {
            return *hzFBAdSize90();
            break;
        }
    }
}



@end
