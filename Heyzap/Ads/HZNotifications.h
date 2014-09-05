//
//  HZNotifications.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/4/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

// These notification names are sent out along with our delegate callbacks for the benefit of mediation.
// Mediation has multiple objects responding to these messages (xpromo + monetized adapters) which makes the notifications convenient
// Mostly we do this so we can pass the auctionType to mediation + any other info mediation needs in the future.

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

@interface HZNotifications : NSObject

@end
