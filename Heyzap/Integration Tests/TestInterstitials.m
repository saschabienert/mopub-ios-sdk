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

- (void)setUpTest {
	// Navigate to the part of the app being exercised by the test cases,
	// initialize SLElements common to the test cases, etc.
}

- (void)tearDownTest {
    [self wait:2];
}

#pragma mark - Portrait Tests

- (void)testPortraitFullscreenCandyCrush
{
    [self testInterstitialWithCreativeID:231237 deviceOrientation:UIDeviceOrientationPortrait];
}

- (void)testPortraitScreenshotsFarmHeroes
{
    [self testInterstitialWithCreativeID:1079355 deviceOrientation:UIDeviceOrientationPortrait];
}

- (void)testPortraitSocialStream
{
    [self testInterstitialWithCreativeID:512037 deviceOrientation:UIDeviceOrientationPortrait];
}

#pragma mark - Landscape Tests

- (void)testLandscapeFullscreenGameOfWar
{
    [self testInterstitialWithCreativeID:495013 deviceOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testLandscapeScreenshotsGameOfWar
{
    [self testInterstitialWithCreativeID:495021 deviceOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testLandscapeFullscreenCleanDragonVale
{
    [self testInterstitialWithCreativeID:554113 deviceOrientation:UIDeviceOrientationLandscapeRight];
}

- (void)testInterstitialWithCreativeID:(const int)creativeID deviceOrientation:(const UIDeviceOrientation)orientation
{
    [[SLDevice currentDevice] setOrientation:orientation];
    [self wait:0.5];
    
    
    id <HZAdsDelegate> delegate = mockProtocol(@protocol(HZAdsDelegate));
    [HeyzapAds setDelegate:delegate];
    
    
    dispatch_sync(dispatch_get_main_queue(), ^{
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
    
    // I think Subliminal is failing on finding elements in landscape, so just close manually.
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZInterstitialAd hide];
    });
    [self wait:1]; // Wait for hide animation to complete.
    SLAssertNoThrow([verify(delegate) didHideAdWithTag:@"default"], @"Delegate should get didHideAd callback");
}

// This test is different b/c it needs to check for audio callbacks, skip the video, etc.
- (void)testVideo
{
    [[SLDevice currentDevice] setOrientation:UIDeviceOrientationLandscapeRight];
    [self wait:0.5];
    id <HZAdsDelegate> delegate = mockProtocol(@protocol(HZAdsDelegate));
    [HeyzapAds setDelegate:delegate];
    
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
    
    SLAssertNoThrow([verifyCount(delegate, atLeastOnce()) willStartAudio], @"Delegate should get willStartAudio callback");
    
    SLAssertNoThrow([verify(delegate) didShowAdWithTag:@"default"], @"Delegate should get didShowAdWithTag callback");
    
    // Wait for skip button to show up.
    [self wait:6];
    
    [[SLDevice currentDevice] captureScreenshotWithFilename:[NSString stringWithFormat:@"Creative%i",videoCreativeID]];
    SLElement *skipButton = [SLElement elementWithAccessibilityLabel:@"skip"]; // Need to give this a label.
    [UIAElement(skipButton) tap];
    
    // I think Subliminal is failing on finding elements in landscape, so just close manually.
    dispatch_sync(dispatch_get_main_queue(), ^{
        [HZVideoAd hide];
    });
    [self wait:1]; // Wait for hide animation to complete.
    SLAssertNoThrow([verify(delegate) didHideAdWithTag:@"default"], @"Delegate should get didHideAd callback");
    SLAssertNoThrow([verify(delegate) didFinishAudio], @"Delegate should get didFinishAudio callback");
}


@end