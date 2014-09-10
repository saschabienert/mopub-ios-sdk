//
//  NativeTableViewController.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/9/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HZNativeAd;

/**
 *  Static Table View for displaying details about a native ad.
 */
@interface NativeAdDetailsTableViewController : UITableViewController

@property (nonatomic) HZNativeAd *nativeAd;

@end
