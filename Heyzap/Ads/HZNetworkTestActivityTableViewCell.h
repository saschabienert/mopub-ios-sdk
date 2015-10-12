//
//  HZTestActivityTableViewCell.h
//  Heyzap
//
//  Created by Maximilian Tagher on 8/21/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HZNetworkTestActivityViewController.h"

@class HZBaseAdapter;
@class HZMediationPersistentConfig;

/**
 The tableview cell that you see on the "index" page of the mediation test suite. This class subscribes to the idea that a `UITableViewCell` should be a controller-type object, so it handles things like target-action from its controls.
 */
@interface HZNetworkTestActivityTableViewCell : UITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier persistentConfig:(HZMediationPersistentConfig *)config tableViewController:(HZNetworkTestActivityViewController *)tableViewController;

- (void)configureWithNetwork:(HZBaseAdapter *)adapter integratedSuccessfully:(BOOL)wasIntegratedSuccesfully;

@end
