//
//  HZLeaderboardPopup.h
//  Heyzap
//
//  Created by Daniel Rhodes on 3/28/13.
//
//

#import "HZTableViewPopup.h"

@class HZLeaderboardRank;

@interface HZLeaderboardPopup : HZTableViewPopup

@property (nonatomic) HZTableViewPopupConfiguration configuration;
@property (nonatomic) HZLeaderboardRank *rank;

- (id) initWithLevelID: (NSString *) levelID;
- (CGRect) CGRectBySettingSize: (CGSize) size andRect: (CGRect) rect;
- (CGRect) CGRectBySettingOrigin: (CGPoint) origin andRect: (CGRect) rect;

- (void) selectLevel: (NSString *) levelID;

@end
