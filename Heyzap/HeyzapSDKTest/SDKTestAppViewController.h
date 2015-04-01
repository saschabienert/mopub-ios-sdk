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

@interface SDKTestAppViewController : BaseTestAppViewController <HZAdsDelegate,UITextFieldDelegate, HZIncentivizedAdDelegate, ChartboostDelegate>

extern NSString * const kCreativeIDTextFieldAccessibilityLabel;
extern NSString * const kShowAdButtonAccessibilityLabel;
extern NSString * const kFetchAdButtonAccessibilityLabel;
extern NSString * const kViewAccessibilityLabel;

@property (nonatomic) UITextField * adsTextField ;

@end
