//
//  HZPersonalBestPopup.h
//  Heyzap
//
//  Created by Daniel Rhodes on 4/2/13.
//
//

#import "HZTableViewPopup.h"

@class HZLeaderboardRank;

@interface HZPersonalBestPopup : HZTableViewPopup

@property (nonatomic, strong) HZLeaderboardRank *rank;
@property (nonatomic) HZTableViewPopupConfiguration configuration;

+ (void)displayPopupWithRank:(HZLeaderboardRank *) rank;
+ (void) dismissPopup;

- (CGRect) CGRectBySettingSize: (CGSize) size andRect: (CGRect) rect;
- (CGRect) CGRectBySettingOrigin: (CGPoint) origin andRect: (CGRect) rect;

@end
