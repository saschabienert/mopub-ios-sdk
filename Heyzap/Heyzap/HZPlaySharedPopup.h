//
//  HZPlaySharedPopup.h
//  Heyzap
//
//  Created by Daniel Rhodes on 4/3/13.
//
//

#import "HZRotatingView.h"
#import "HZImageView.h"

@class HZUser;

@interface HZPlaySharedPopup : HZRotatingView

@property (strong, nonatomic) UIImageView *backgroundView;
@property (strong, nonatomic) UIImageView *logoImage;
@property (strong, nonatomic) HZImageView *userImage;
@property (strong, nonatomic) UIView *userImageShadow;
@property (strong, nonatomic) UILabel *calloutLabel;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) HZUser *user;


+ (void) displayPopupWithUser: (HZUser *) user;
+ (void) displayPopupWithUser:(HZUser *)user andTimeout: (NSTimeInterval) timeout;
+ (void) dismissPopup;
+ (void) moveForGameCenter;

- (id) initWithUser:(HZUser *) user;
- (void) showWithTimeout: (NSTimeInterval) timeout;
- (void) show;
- (void) dismiss;
- (void) sizeToFitOrientation:(BOOL)transform;
- (void) didAction: (id) sender;
- (void) moveBackAfterGameCenter;

@end
