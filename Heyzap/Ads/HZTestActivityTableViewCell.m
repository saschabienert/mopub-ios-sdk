//
//  HZTestActivityTableViewCell.m
//  Heyzap
//
//  Created by Maximilian Tagher on 8/21/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZTestActivityTableViewCell.h"
#import "HZBaseAdapter.h"
#import "HZMediationPersistentConfig.h"
#import "HZDevice.h"

@interface HZTestActivityTableViewCell()

@property (nonatomic, strong) HZMediationPersistentConfig *config;
@property (nonatomic, strong) UISwitch *networkOnSwitch;
@property (nonatomic, weak) HZBaseAdapter *adapter;
@property (nonatomic, weak) HZTestActivityViewController *tableViewController;
@end

@implementation HZTestActivityTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier persistentConfig:(HZMediationPersistentConfig *)config tableViewController:(HZTestActivityViewController *)tableViewController{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    HZParameterAssert(config);
    if (self) {
        _config = config;
        _tableViewController = tableViewController;
        
        self.networkOnSwitch = [[UISwitch alloc] init];
        [self.networkOnSwitch addTarget:self action:@selector(networkEnableSwitchFlipped:) forControlEvents:UIControlEventValueChanged];
        
        if ([self showNetworkSwitch]) {
            //self.networkOnSwitch
            self.accessoryView = self.networkOnSwitch;
        }
    }
    return self;
}

- (BOOL)showNetworkSwitch {
    if (self.tableViewController) {
        return [self.tableViewController showNetworkEnableSwitch];
    }
    
    return NO;
}

#pragma mark - cellForRowAtIndexPath: configuration

- (void)configureWithNetwork:(HZBaseAdapter *)adapter integratedSuccessfully:(BOOL)wasIntegratedSuccessfully {
    self.adapter = adapter;
    
    self.textLabel.text = [[self.adapter class] humanizedName];
    
    self.detailTextLabel.text = wasIntegratedSuccessfully ? @"☑︎" : @"☒";
    self.detailTextLabel.textColor = wasIntegratedSuccessfully ? [UIColor greenColor] : [UIColor redColor];
    
    self.networkOnSwitch.on = [self.config isNetworkEnabled:[adapter name]];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if ([self showNetworkSwitch]) {
        // Add padding between the checkmark / x and the UISwitch
        CGRect frame = self.detailTextLabel.frame;
        frame.origin.x -= 10;
        self.detailTextLabel.frame = frame;
    }
}

#pragma mark - Target-Action

- (void)networkEnableSwitchFlipped:(UISwitch *)theSwitch {
    if (theSwitch.isOn) {
        [self.config removeDisabledNetwork:[self.adapter name]];
    } else {
        [self.config addDisabledNetwork:[self.adapter name]];
    }
}

- (void) updateNetworkEnableSwitch {
    self.networkOnSwitch.on = [self.config isNetworkEnabled:[self.adapter name]];
}

@end
