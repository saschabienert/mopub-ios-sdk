//
//  MediatedNativeAdTableViewController.m
//  Heyzap
//
//  Created by Maximilian Tagher on 10/28/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "MediatedNativeAdTableViewController.h"
#import "MediatedNativeTableViewCell.h"
#import "HZMediatedNativeAd.h"
#import "HeyzapMediation.h"
#import "HZFetchOptions.h"
#import "HZMediatedNativeAdManager_Private.h"

@interface MediatedNativeAdTableViewController()

@property (nonatomic) NSMutableArray <HZMediatedNativeAd *> *ads;

@end

@implementation MediatedNativeAdTableViewController

#pragma mark - Properties

- (NSMutableArray <HZMediatedNativeAd *> *)ads {
    if (!_ads) {
        _ads = [NSMutableArray array];
    }
    return _ads;
}

#pragma mark - View Controller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(hide)];
    button.tintColor = [UIColor whiteColor];
    [self.navigationItem setLeftBarButtonItem:button animated:NO];
    self.title = @"Mediated Native";
    
    
    [self.tableView registerClass:[MediatedNativeTableViewCell class] forCellReuseIdentifier:@"MediatedNativeTableViewCell"];
    
    [self insertBatchOfAds];
    [self performSelector:@selector(insertBatchOfAds) withObject:nil afterDelay:2];
    [self performSelector:@selector(insertBatchOfAds) withObject:nil afterDelay:4];
}

- (void)insertBatchOfAds {
    NSArray *networks = @[@"heyzap", @"heyzap_cross_promo", @"facebook", @"admob"];
    
    [networks enumerateObjectsUsingBlock:^(NSString * _Nonnull network, NSUInteger idx, __unused BOOL * _Nonnull stop) {
        HZFetchOptions *options = [[HZFetchOptions alloc] init];
        options.presentingViewController = self;
        options.requestingAdType = HZAdTypeNative;
        NSDictionary *const additionalParameters = @{@"network": network};
        options.additionalParameters = additionalParameters;
        options.completion = ^(BOOL success, NSError *error) {
            NSError *nativeError;
            HZMediatedNativeAd *ad = [HZMediatedNativeAdManager getNextNativeAdForTag:@"default"
                                                                     additionalParams:additionalParameters
                                                                                error:&nativeError];
            if (ad) {
                ad.presentingViewController = self;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.ads count] inSection:0];
                [self.ads addObject:ad];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                NSLog(@"No native ad was available for %@. Error = %@", network, nativeError);
            }
        };
        
        [HZMediatedNativeAdManager fetchNativeAdWithOptions:options];
    }];
}

#pragma mark - UITableViewDelegate / UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.ads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediatedNativeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediatedNativeTableViewCell" forIndexPath:indexPath];
    
    HZMediatedNativeAd *ad = self.ads[indexPath.row];
    
    [cell configureWithNativeAd:ad];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 320;
}

#pragma mark - Target Action

- (void)hide {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Configuration

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
