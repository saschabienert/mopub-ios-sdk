//
//  HeyzapSDKTestAppViewController.h
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Heyzap/Heyzap.h>
#import "BaseTestAppViewController.h"

@interface SDKTestAppViewController : BaseTestAppViewController <HZAdsDelegate,UITextFieldDelegate, HZIncentivizedAdDelegate>

extern NSString * const kCreativeIDTextFieldAccessibilityLabel;
extern NSString * const kShowAdButtonAccessibilityLabel;

@property (nonatomic) float score;
@property (nonatomic) UITextField * adsTextField ;

@end
