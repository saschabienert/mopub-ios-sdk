//
//  HZVideoAdDisplayOptions.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

@interface HZVideoAdDisplayOptions : NSObject

- (instancetype)initWithDefaultsDictionary:(NSDictionary *)defaultsDictionary adUnitDictionary:(NSDictionary *)adUnitsDictionary;

// On-screen Video Behaviors
@property (nonatomic, readonly) NSNumber *lockoutTime;
@property (nonatomic, readonly) BOOL allowSkip;
@property (nonatomic, readonly) BOOL allowHide;
@property (nonatomic, readonly) BOOL allowInstallButton;
@property (nonatomic, readonly) BOOL allowAdTimer;
@property (nonatomic, readonly) BOOL postRollInterstitial;

@property (nonatomic, readonly) NSString *installButtonText; //i.e.: "Install Now"
@property (nonatomic, readonly) NSString *skipNowText; // i.e.: "Skip"
@property (nonatomic, readonly) NSString *skipLaterFormattedText; // i.e.: "Skip in %is" (where '%i' will be replaced by the time remaining in seconds later)

@property (nonatomic, readonly) BOOL allowFallbacktoStreaming;
@property (nonatomic, readonly) BOOL forceStreaming;


@end