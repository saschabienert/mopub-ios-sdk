//
//  NativeAdTableViewController.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZNativeAdCollection;

/**
 *  Table View Controller displaying a list of native ads.
 */
@interface NativeAdTableViewController : UITableViewController

@property (nonatomic, strong) HZNativeAdCollection *adCollection;

@end
