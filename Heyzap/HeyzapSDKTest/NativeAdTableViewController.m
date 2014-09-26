//
//  NativeAdTableViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "NativeAdTableViewController.h"
#import "HZNativeAdCollection.h"
#import "HZNativeAd.h"
#import "NativeTableViewCell.h"
#import "NativeAdDetailsTableViewController.h"

@interface NativeAdTableViewController ()

@end

@implementation NativeAdTableViewController

NSString *const kNativeCellIdentifier = @"nativeCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSParameterAssert(self.adCollection);
    
    [self.adCollection reportImpressionOnAllAds];
}

#pragma mark - Table view data source

- (HZNativeAd *)adModelAtIndexPath:(NSIndexPath *)indexPath {
    return self.adCollection.ads[indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.adCollection.ads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NativeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"nativeCellReuseIdentifier" forIndexPath:indexPath];
    
    HZNativeAd *ad = [self adModelAtIndexPath:indexPath];
    
    [cell configureWithAd:ad];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    HZNativeAd *nativeAd = [self adModelAtIndexPath:indexPath];
    
    NativeAdDetailsTableViewController *vc = segue.destinationViewController;
    vc.nativeAd = nativeAd;
}

#pragma mark - Target Action

- (IBAction)dismissController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
