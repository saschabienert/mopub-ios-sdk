//
//  MediatedNativeTableViewCell.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZMediatedNativeAd;

@interface MediatedNativeTableViewCell : UITableViewCell

- (void)configureWithNativeAd:(HZMediatedNativeAd *)nativeAd;

@end
