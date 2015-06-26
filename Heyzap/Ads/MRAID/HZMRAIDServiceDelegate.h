//
//  SKMRAIDServiceDelegate.h
//  MRAID
//
//  Created by Thomas Poland on 10/21/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

static NSString* HZMRAIDSupportsSMS = @"sms";
static NSString* HZMRAIDSupportsTel = @"tel";
static NSString* HZMRAIDSupportsCalendar = @"calendar";
static NSString* HZMRAIDSupportsStorePicture = @"storePicture";
static NSString* HZMRAIDSupportsInlineVideo = @"inlineVideo";

// A delegate for MRAIDView/MRAIDInterstitial to listen for notifications when the following events
// are triggered from a creative: SMS, Telephone call, Calendar entry, Play Video (external) and
// saving pictures. If you don't implement this protocol, the default for
// supporting these features for creative will be FALSE.
@protocol HZMRAIDServiceDelegate <NSObject>

@optional

// These callbacks are to request other services.
- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSON;
- (void)mraidServicePlayVideoWithURL:(NSURL *)URL;
- (void)mraidServiceOpenBrowserWithURL:(NSURL *)URL;
- (void)mraidServiceStorePictureWithURL:(NSURL *)URL;

@end
