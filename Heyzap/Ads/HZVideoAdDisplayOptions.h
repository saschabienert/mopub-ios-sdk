//
//  HZVideoAdDisplayOptions.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

@interface HZVideoAdDisplayOptions : NSObject

/**
 *  Call this method to set up the defaults used for all future instantiations of this class using initWithDict:.
 */
+ (void) setDefaultsWithDict:(NSDictionary *)dict;

/**
 *  This method will use the defaults set by a prior call to setDefaultsWithDict:, overriding them with any settings passed in the dictionary, to create a HZVideoAdDisplayOptions object.
 */
- (instancetype) initWithDict:(NSDictionary *)dict;

/**
 *  Returns an instance of HZVideoAdDisplayOptions created solely with the defaults previously set with a call to setDefaultsWithDict:.
 */
+ (HZVideoAdDisplayOptions *) defaults;

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