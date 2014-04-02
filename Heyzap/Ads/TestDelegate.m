//
//  TestDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/2/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "TestDelegate.h"

@implementation TestDelegate

- (void)didShowAdWithTag: (NSString *) tag
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

- (void)didFailToShowAdWithTag: (NSString *) tag andError: (NSError *)error
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

- (void)didReceiveAdWithTag: (NSString *) tag
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

- (void)didFailToReceiveAdWithTag: (NSString *) tag
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

- (void)didClickAdWithTag: (NSString *) tag
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

- (void)didHideAdWithTag: (NSString *) tag
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

/**
 *  Called when an ad will use audio
 */
- (void)willStartAudio
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

/**
 *  Called when an ad will finish using audio
 */
- (void) didFinishAudio
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

/** Called when a user successfully completes viewing an ad */
- (void)didCompleteAd
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}
/** Called when a user does not complete the viewing of an ad */
- (void)didFailToCompleteAd
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

@end
