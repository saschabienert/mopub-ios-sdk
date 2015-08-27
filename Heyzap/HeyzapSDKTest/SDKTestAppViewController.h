//
//  HeyzapSDKTestAppViewController.h
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTestAppViewController.h"
#import "HeyzapAds.h"
#import "Chartboost.h"

@interface SDKTestAppViewController : BaseTestAppViewController <UITextFieldDelegate>

extern NSString * const kCreativeIDTextFieldAccessibilityLabel;
extern NSString * const kShowAdButtonAccessibilityLabel;
extern NSString * const kFetchAdButtonAccessibilityLabel;
extern NSString * const kViewAccessibilityLabel;

@property (nonatomic) UITextField * adsTextField ;

- (void) logCallback:(NSString *)callbackName;
- (void) logCallback:(NSString *)callbackName withString:(NSString *)string;

@end


@interface SDKTestAppViewControllerAdCallbackDelegate : NSObject
@property (nonatomic) SDKTestAppViewController *vc;
@property (nonatomic) NSString *name;

- (instancetype) initWthSDKTestAppViewController:(SDKTestAppViewController *)vc;

@end

@interface SDKTestAppViewControllerHZAdsDelegate : SDKTestAppViewControllerAdCallbackDelegate <HZAdsDelegate>

@end

@interface SDKTestAppViewControllerHZIncentivizedAdDelegate : SDKTestAppViewControllerHZAdsDelegate <HZIncentivizedAdDelegate>
@end

@interface SDKTestAppViewControllerHZBannerAdDelegate : SDKTestAppViewControllerAdCallbackDelegate <HZBannerAdDelegate>

@end