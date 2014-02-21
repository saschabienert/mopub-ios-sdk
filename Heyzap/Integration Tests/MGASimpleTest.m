//
//  MGASimpleTest.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/7/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Subliminal/Subliminal.h>
#import "SDKTestAppViewController.h"
#import "SLTerminal.h"

@interface MGASimpleTest : SLTest

@end

@implementation MGASimpleTest

- (void)setUpTest {
	// Navigate to the part of the app being exercised by the test cases,
	// initialize SLElements common to the test cases, etc.
    [[SLDevice currentDevice] setOrientation:UIDeviceOrientationPortrait];
}

- (void)tearDownTest {
	// Navigate back to "home", if applicable.
    [self wait:2];
}

- (void)resetTextField
{
    SDKTestAppViewController *adViewController = (id) [[[UIApplication sharedApplication] keyWindow] rootViewController];
    adViewController.adsTextField.text = @"";
}

NSString * const kSmallInterstitialCreativeID = @"166101"; // Candy crush saga
NSString * const kPortraitFullScreenInterstitialCreativeID = @"231237"; // Candy crush saga

- (void)testClickingSmallInterstitial
{
    [self resetTextField];
    [self showAdForCreativeID:kSmallInterstitialCreativeID];
    [self clickAd];
}

- (void)testClosingSmallInterstitial
{
    [self resetTextField];
    [self showAdForCreativeID:kSmallInterstitialCreativeID];
    [self closeAd];
}

- (void)testClosingPortraitFullScreen
{
    [self resetTextField];
    [self showAdForCreativeID:kPortraitFullScreenInterstitialCreativeID];
    [self closeAd];
}

- (void)testPortraitFullScreen
{
    [self resetTextField];
    [self showAdForCreativeID:kPortraitFullScreenInterstitialCreativeID];
    [self clickAd];
}
- (void)showAdForCreativeID:(NSString *)creativeID
{
    [self resetTextField];
    SLTextField *textField = [SLTextField elementWithAccessibilityLabel:kCreativeIDTextFieldAccessibilityLabel];
    [textField setText:creativeID ?: @""];
    
    SLButton *showAdButton = [SLButton elementWithAccessibilityLabel:kShowAdButtonAccessibilityLabel];
    SLAssertTrue([UIAElement(showAdButton) isValidAndVisible], @"showAdButton should be valid and visible");
    
    [showAdButton tap];
    [self wait:1.5]; // Manually wait for the screenshot.
    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().captureScreenWithName(\"Creative%@\")",creativeID];
}

- (void)clickAd
{
    [self resetTextField];
    SLElement *installButton = [SLElement elementWithAccessibilityLabel:@"Install for Free"];
    [UIAElement(installButton) tap];
    
    
    SLStaticElement *cancel = [[SLStaticElement alloc] initWithUIARepresentation:@"UIATarget.localTarget().frontMostApp().navigationBar().leftButton()"];
    SLAssertTrueWithTimeout([UIAElement(cancel) isValidAndVisible], 2, @"After clicking the ad, we should see the cancel button of the SKStoreProductViewController");
    
    [cancel tap];
    
    SLAssertTrue([installButton isInvalidOrInvisible], @"We should no longer see the install button.");
}

- (void)closeAd
{
    [self resetTextField];
    SLElement *closeButton = [SLElement elementWithAccessibilityLabel:@"Close Ad"];
    SLAssertTrueWithTimeout(UIAElement([closeButton isValidAndVisible]), 4, @"We should see close button after showing ad");
    
    [closeButton tap];
    
    SLAssertTrueWithTimeout([closeButton isInvalidOrInvisible], 4, @"After clicking close, we shouldn't see close button");
}


@end
