//
//  HZAdController.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HZAdModel.h"

@protocol HZAdPopupActionDelegate<NSObject>

- (void) onActionHide: (id) sender;
- (void) onActionShow: (id) sender;
- (void) onActionReady: (id) sender;
- (void) onActionClick: (id) sender withURL: (NSURL *) url;
- (void) onActionCompleted: (id) sender;
- (void) onActionError: (id) sender;
- (void) onActionRestart: (id) sender;
- (void) onActionInstallHeyzap: (id) sender;

@end

@interface HZAdViewController : UIViewController

@property (nonatomic) HZAdModel *ad;

- (id) initWithAd: (HZAdModel *) ad;
- (void) show;
- (void) hide;

- (void) didClickWithURL: (NSURL *) url;
- (void) didImpression;
- (void) didClickHeyzapInstall;

- (BOOL) applicationSupportsLandscape;

@end
