//
//  HZScorePopup.h
//  Heyzap
//
//  Created by Simon Maynard on 9/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZRotatingView.h"
#import "Heyzap.h"
#import "HZImageView.h"

@class HZLeaderboardRank;

@interface HZScorePopup : HZRotatingView

@property (strong, nonatomic) UIImageView *backgroundView;
@property (strong, nonatomic) UIImageView *logoImage;
@property (strong, nonatomic) HZImageView *userImage;
@property (strong, nonatomic) UIView *userImageShadow;
@property (strong, nonatomic) UILabel *calloutLabel;
@property (strong, nonatomic) UILabel *currentScoreLabel;
@property (strong, nonatomic) UILabel *subCalloutLabel;
@property (strong, nonatomic) UILabel *highScoreLabel;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) HZLeaderboardRank *rank;


+ (void)displayPopupWithRank:(HZLeaderboardRank *) rank;
+ (void) displayPopupWithRank:(HZLeaderboardRank *)rank andTimeout: (NSTimeInterval) timeout;
+ (void) dismissPopup;
+ (void) moveForGameCenter;

- (id) initWithRank:(HZLeaderboardRank *) rank;
- (void) showWithTimeout: (NSTimeInterval) timeout;
- (void) show;
- (void) dismiss;
- (void) sizeToFitOrientation:(BOOL)transform;
- (void) didAction: (id) sender;
- (void) moveBackAfterGameCenter;
@end