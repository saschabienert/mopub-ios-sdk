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

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@interface MGASimpleTest : SLTest

@end

@implementation MGASimpleTest

#pragma mark - Setup

- (void)setUpTest {
	// Navigate to the part of the app being exercised by the test cases,
	// initialize SLElements common to the test cases, etc.
}

- (void)tearDownTest {
//    [self wait:2];
}

#pragma mark - Portrait Tests

- (void)testPortraitFullscreenCandyCrush
{
    [self testInterstitialWithCreativeID:231237 useTestCreative:NO deviceOrientation:UIDeviceOrientationPortrait];
}

- (void)testPortraitScreenshotsFarmHeroes
{
    [self testInterstitialWithCreativeID:1079355 useTestCreative:NO deviceOrientation:UIDeviceOrientationPortrait];
}

#pragma mark - Landscape Tests

- (void)testLandscapeFullscreenBookOfRa
{
    [self testInterstitialWithCreativeID:2205811 useTestCreative:NO deviceOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testLandscapeScreenshotsBookOfRa
{
    [self testInterstitialWithCreativeID:2205823 useTestCreative:NO deviceOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testLandscapeFullscreenCleanDragonVale
{
    [self testInterstitialWithCreativeID:554113 useTestCreative:NO deviceOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testLandscapeTestCreative
{
    [self testInterstitialWithCreativeID:0 useTestCreative:YES deviceOrientation:UIDeviceOrientationLandscapeLeft];
}

- (void)testPortraitTestCreative
{
    [self testInterstitialWithCreativeID:0 useTestCreative:YES deviceOrientation:UIDeviceOrientationPortrait];
}

- (void)testInterstitialWithCreativeID:(const int)creativeID useTestCreative:(BOOL)useTestCreative deviceOrientation:(const UIDeviceOrientation)orientation
{
    [[SLDevice currentDevice] setOrientation:orientation];
    [self wait:0.5];
    
    
    id <HZAdsDelegate> delegate = mockProtocol(@protocol(HZAdsDelegate));
    [HZInterstitialAd setDelegate:delegate];
    
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZInterstitialAd forceTestCreative:useTestCreative];
        [HZInterstitialAd setCreativeID:creativeID];
        [HZInterstitialAd fetch];
    });
    
    
    waitUntil(^BOOL{
        return [HZInterstitialAd isAvailable];
    }, 10);
    
    SLAssertNoThrow([verify(delegate) didReceiveAdWithTag:@"default"], @"Delegate should get didReceiveAdWithTag callback");
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZInterstitialAd show];
    });
    
    [self wait:1]; // wait for screenshot
    
    [[SLDevice currentDevice] captureScreenshotWithFilename:[NSString stringWithFormat:@"Creative%i",creativeID]];
    
    SLAssertNoThrow([verify(delegate) didShowAdWithTag:@"default"], @"Delegate should get didShowAdWithTag callback");
    
    SLElement *closeButton = [SLElement elementWithAccessibilityLabel:@"Close Ad"];
    [closeButton tap];
    
    [self wait:1]; // Wait for hide animation to complete.
    SLAssertNoThrow([verify(delegate) didHideAdWithTag:@"default"], @"Delegate should get didHideAd callback");
}

#pragma mark - Video

// This test is different b/c it needs to check for audio callbacks, skip the video, etc.
- (void)testVideo
{
    if ([[NSProcessInfo processInfo] environment][@"TRAVIS"] != nil) {
        SLLog(@"Travis CI has trouble with the video ad; skipping this test.");
        return;
    }
    
    [[SLDevice currentDevice] setOrientation:UIDeviceOrientationLandscapeRight];
    [self wait:0.5];
    id <HZAdsDelegate> delegate = mockProtocol(@protocol(HZAdsDelegate));
    [HZVideoAd setDelegate:delegate];
    
    static const int videoCreativeID = 1246917;
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZVideoAd setCreativeID:videoCreativeID];
        [HZVideoAd fetch];
    });
    
    waitUntil(^BOOL{
        return [HZVideoAd isAvailable];
    }, 15);
    
    SLAssertNoThrow([verify(delegate) didReceiveAdWithTag:@"default"], @"Delegate should get didReceiveAdWithTag callback");
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZVideoAd show];
    });
    
    [self wait:1];
    
    SLAssertNoThrow([verify(delegate) willStartAudio], @"Delegate should get willStartAudio callback");
    
    SLAssertNoThrow([verify(delegate) didShowAdWithTag:@"default"], @"Delegate should get didShowAdWithTag callback");
    
    // Wait for skip button to show up.
    [self wait:6];
    
    [[SLDevice currentDevice] captureScreenshotWithFilename:[NSString stringWithFormat:@"Creative%i",videoCreativeID]];
    SLElement *skipButton = [SLElement elementWithAccessibilityLabel:@"skip"]; // Need to give this a label.
    [UIAElement(skipButton) tap];
    
    SLElement *closeButton = [SLElement elementWithAccessibilityLabel:@"Close Ad"];
    [closeButton tap];
    
    [self wait:1]; // Wait for hide animation to complete.
    SLAssertNoThrow([verify(delegate) didHideAdWithTag:@"default"], @"Delegate should get didHideAd callback");
    SLAssertNoThrow([verify(delegate) didFinishAudio], @"Delegate should get didFinishAudio callback");
}


@end