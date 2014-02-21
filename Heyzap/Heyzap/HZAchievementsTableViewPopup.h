//
//  HZAchievementsTableViewPopup.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZTableViewPopup.h"

@interface HZAchievementsTableViewPopup : HZTableViewPopup

@property (nonatomic) HZTableViewPopupConfiguration configuration;

@property (nonatomic, strong) NSArray *achievements;

CGRect CGRectBySettingSize(CGRect rect, CGSize size);

CGRect CGRectBySettingOrigin(CGRect rect, CGPoint origin);

@end
