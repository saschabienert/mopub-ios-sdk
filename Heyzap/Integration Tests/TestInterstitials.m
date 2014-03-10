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
#import "UIViewController+IntegrationTests.h"
#import "TestUtilities.h"

@interface MGASimpleTest : SLTest

@end

@implementation MGASimpleTest

- (void)setUpTest {
	// Navigate to the part of the app being exercised by the test cases,
	// initialize SLElements common to the test cases, etc.
}

- (void)tearDownTest {
	// Navigate back to "home", if applicable.
}

- (void)resetTextField
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        SDKTestAppViewController *adViewController = [[self class] testViewController];
        adViewController.adsTextField.text = @"";
    });
}

+ (SDKTestAppViewController *)testViewController
{
    UIViewController *rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    return (id) [rootVC recursiveChildViewController];
}

NSString * const kPortraitFullScreenInterstitialCreativeID = @"231237"; // Candy crush saga
NSString * const kVideoAdCreativeID = @"1246917"; // ?

- (void)testClosingPortraitFullScreen
{
    [[SLDevice currentDevice] setOrientation:UIDeviceOrientationPortrait];
    [self resetTextField];
    [self showAdForCreativeID:kPortraitFullScreenInterstitialCreativeID];
    [self closeAd];
}

- (void)testLandscape
{
    [[SLDevice currentDevice] setOrientation:UIDeviceOrientationLandscapeLeft];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZInterstitialAd setCreativeID:512999];
        [HZInterstitialAd fetch];
    });
    
    waitUntil(^BOOL{
        return [HZInterstitialAd isAvailable];
    }, 10);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
    });
}

- (void)focus_testVideo
{
    static const int videoCreativeID = 1246917;
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZVideoAd setCreativeID:videoCreativeID];
        [HZVideoAd fetch];
    });
    
    waitUntil(^BOOL{
        return [HZVideoAd isAvailable];
    }, 15);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZVideoAd show];
    });
    
    
    // Wait for skip button to show up.
    [self wait:6];
    
    [[SLDevice currentDevice] captureScreenshotWithFilename:[NSString stringWithFormat:@"Creative%i",videoCreativeID]];
    SLElement *skipButton = [SLElement elementWithAccessibilityLabel:@"skip"]; // Need to give this a label.
    [UIAElement(skipButton) tap];
    
//    [self closeAd];
}

- (void)showAdForCreativeID:(NSString *)creativeID
{
    [self resetTextField];
    SLTextField *textField = [SLTextField elementWithAccessibilityLabel:kCreativeIDTextFieldAccessibilityLabel];
    [textField setText:creativeID ?: @""];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[[[self class] testViewController] view] endEditing:YES];
    });
    
    SLButton *fetchAdButton = [SLButton elementWithAccessibilityLabel:kFetchAdButtonAccessibilityLabel];
    
    SLAssertTrue([fetchAdButton isValid], @"Button is valid");
    SLLog(@"isValid = %i",[fetchAdButton isValid]);
    SLAssertTrue([fetchAdButton isVisible], @"is also visible");
    
    SLAssertTrue([UIAElement(fetchAdButton) isValidAndVisible], @"fetchAdButton should be valid and visible");
    
    [UIAElement(fetchAdButton) tap];
    
    // Wait for the fetch.
    [self wait:1.5];
    
    SLButton *showAdButton = [SLButton elementWithAccessibilityLabel:kShowAdButtonAccessibilityLabel];
    SLAssertTrue([UIAElement(showAdButton) isValidAndVisible], @"showAdButton should be valid and visible");
    
    
    [showAdButton tap];
    [self wait:1]; // Manually wait for the screenshot.
    [[SLTerminal sharedTerminal] evalWithFormat:@"UIATarget.localTarget().captureScreenWithName(\"Creative%@\")",creativeID];
}

- (void)clickAd
{
    [self wait:2];
    SLLog(@"Clicking Ad");
    SLElement *installButton = [SLElement elementWithAccessibilityLabel:@"Install for Free"];
    SLLog(@"Install button = %@",installButton);
    SLAssertTrue([UIAElement(installButton) isValidAndVisible], @"install button should be visible");
    [installButton logElement];
    [installButton tap];
    
    SLLog(@"Canceling");
    SLStaticElement *cancel = [[SLStaticElement alloc] initWithUIARepresentation:@"UIATarget.localTarget().frontMostApp().navigationBar().leftButton()"];
    SLAssertTrueWithTimeout([UIAElement(cancel) isValidAndVisible], 2, @"After clicking the ad, we should see the cancel button of the SKStoreProductViewController");
    
    [cancel tap];
    
    SLAssertTrue([installButton isInvalidOrInvisible], @"We should no longer see the install button.");
}

- (void)closeAd
{
    SLElement *closeButton = [SLElement elementWithAccessibilityLabel:@"Close Ad"];
    SLAssertTrueWithTimeout(UIAElement([closeButton isValidAndVisible]), 4, @"We should see close button after showing ad");
    
    [closeButton tap];
    
    SLAssertTrueWithTimeout([closeButton isInvalidOrInvisible], 4, @"After clicking close, we shouldn't see close button");
}


@end