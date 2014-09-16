//
//  NativeTableViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/9/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "NativeAdDetailsTableViewController.h"
#import "HZNativeAd.h"

@interface NativeAdDetailsTableViewController () <SKStoreProductViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *developerLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;


@end

@implementation NativeAdDetailsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.appNameLabel.text = self.nativeAd.appName;
    self.ratingLabel.text = self.nativeAd.rating.stringValue;
    self.categoryLabel.text = self.nativeAd.category;
    self.developerLabel.text = self.nativeAd.developerName;
    self.descriptionLabel.text = self.nativeAd.appDescription;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Prevent selection
    return nil;
}

- (IBAction)openAppStore:(id)sender {
    
    // Loading spinner start
    [self.nativeAd presentAppStoreFromViewController:self
                                       storeDelegate:self
                                          completion:^(BOOL result, NSError *error) {
        // Loading spinner end.
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
