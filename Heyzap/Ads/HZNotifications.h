//
//  HZNotifications.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/4/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kHeyzapDidShowAdNotitification;
extern NSString *const kHeyzapDidFailToShowAdNotification;
extern NSString *const kHeyzapDidReceiveAdNotification;
extern NSString *const kHeyzapDidFailToReceiveAdNotification;

extern NSString *const kHeyzapDidClickAdNotification;
extern NSString *const kHeyzapDidHideAdNotification;
extern NSString *const kHeyzapWillStartAudio;
extern NSString *const kHeyzapDidFinishAudio;

extern NSString *const kHeyzapDidCompleteIncentivizedAd;
extern NSString *const kHeyzapDidFailToCompleteIncentivizedAd;

// Dictionary Keys
extern NSString *const kHeyzapTagKey;
extern NSString *const kHeyzapAdUnitKey;
extern NSString *const kHeyzapAuctionTypeKey;

@interface HZNotifications : NSObject

@end
