//
//  SKMRAIDModalViewController.m
//  MRAID
//
//  Created by Jay Tucker on 9/20/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "HZMRAIDModalViewController.h"

#import "HZMRAIDUtil.h"
#import "HZMRAIDLogger.h"
#import "HZMRAIDOrientationProperties.h"

@interface HZMRAIDModalViewController ()

@property (nonatomic) BOOL isStatusBarHidden;
@property (nonatomic) BOOL hasViewAppeared;
@property (nonatomic) BOOL hasRotated;

@property (nonatomic, strong) HZMRAIDOrientationProperties *orientationProperties;
@property (nonatomic) UIInterfaceOrientation preferredOrientation;

- (NSString *)stringfromUIInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end

@implementation HZMRAIDModalViewController

- (id)init
{
    return [self initWithOrientationProperties:nil];
}

- (id)initWithOrientationProperties:(HZMRAIDOrientationProperties *)orientationProps
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        if (orientationProps) {
            _orientationProperties = orientationProps;
        } else {
            _orientationProperties = [[HZMRAIDOrientationProperties alloc] init];
        }
        
        UIInterfaceOrientation currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

        // If the orientation is forced, accomodate it.
        // If it's not fored, then match the current orientation.
        if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationPortrait) {
            _preferredOrientation = UIInterfaceOrientationPortrait;
        } else  if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationLandscape) {
            if (UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) {
                _preferredOrientation = currentInterfaceOrientation;
            } else {
                _preferredOrientation = UIInterfaceOrientationLandscapeLeft;
            }
        } else {
            // orientationProperties.forceOrientation == MRAIDForceOrientationNone
            _preferredOrientation = currentInterfaceOrientation;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - status bar

// This is to hide the status bar on iOS 6 and lower.
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat:@"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];

    _isStatusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat:@"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    _hasViewAppeared = YES;
    
    if (_hasRotated) {
        [self.delegate mraidModalViewControllerDidRotate:self];
        _hasRotated = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")){
        [[UIApplication sharedApplication] setStatusBarHidden:_isStatusBarHidden withAnimation:UIStatusBarAnimationFade];
    }
}

// This is to hide the status bar on iOS 7.
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - rotation/orientation

- (BOOL)shouldAutorotate
{
    NSArray *supportedOrientationsInPlist = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    
    BOOL isPortraitSupported = [supportedOrientationsInPlist containsObject:@"UIInterfaceOrientationPortrait"];
    BOOL isPortraitUpsideDownSupported = [supportedOrientationsInPlist containsObject:@"UIInterfaceOrientationPortraitUpsideDown"];
    BOOL isLandscapeLeftSupported = [supportedOrientationsInPlist containsObject:@"UIInterfaceOrientationLandscapeLeft"];
    BOOL isLandscapeRightSupported = [supportedOrientationsInPlist containsObject:@"UIInterfaceOrientationLandscapeRight"];
    
    UIInterfaceOrientation currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    BOOL retval = NO;

    if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationPortrait) {
        retval = (isPortraitSupported && isPortraitUpsideDownSupported);
    } else if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationLandscape) {
        retval = (isLandscapeLeftSupported && isLandscapeRightSupported);
    } else {
        // orientationProperties.forceOrientation == MRAIDForceOrientationNone
        if (_orientationProperties.allowOrientationChange) {
            retval = YES;
        } else {
            if (UIInterfaceOrientationIsPortrait(currentInterfaceOrientation)) {
                retval = (isPortraitSupported && isPortraitUpsideDownSupported);
            } else {
                // currentInterfaceOrientation is landscape
                return (isLandscapeLeftSupported && isLandscapeRightSupported);
            }
        }
    }
    
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat: @"%@ %@ %@", [self.class description], NSStringFromSelector(_cmd), (retval ? @"YES" : @"NO")]];
    return retval;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat: @"%@ %@ %@",
                            [self.class description],
                            NSStringFromSelector(_cmd),
                            [self stringfromUIInterfaceOrientation: _preferredOrientation]]];
    return _preferredOrientation;
}

- (NSUInteger)supportedInterfaceOrientations
{
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationPortrait) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationLandscape) {
        return UIInterfaceOrientationMaskLandscape;
    }
    
    // orientationProperties.forceOrientation == MRAIDForceOrientationNone
    
    if (!_orientationProperties.allowOrientationChange) {
        if (UIInterfaceOrientationIsPortrait(_preferredOrientation)) {
            return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
        } else {
            return UIInterfaceOrientationMaskLandscape;
        }
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    // willRotateToInterfaceOrientation code goes here
    
    __block HZMRAIDModalViewController *blockSelf = self;
   
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // willAnimateRotationToInterfaceOrientation code goes here
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // didRotateFromInterfaceOrientation goes here
        if (blockSelf.hasViewAppeared) {
            [blockSelf.delegate mraidModalViewControllerDidRotate:blockSelf];
            blockSelf.hasRotated = NO;
        }
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIInterfaceOrientation toInterfaceOrientation = self.interfaceOrientation;
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat:@"%@ %@from %@ to %@",
                      [self.class description],
                      NSStringFromSelector(_cmd),
                      [self stringfromUIInterfaceOrientation:fromInterfaceOrientation],
                      [self stringfromUIInterfaceOrientation:toInterfaceOrientation]]];
    
    if (_hasViewAppeared) {
        [self.delegate mraidModalViewControllerDidRotate:self];
        _hasRotated = NO;
    }
}

- (void)forceToOrientation:(HZMRAIDOrientationProperties *)orientationProps
{
    NSString *orientationString;
    switch (orientationProps.forceOrientation) {
        case HZMRAIDForceOrientationPortrait:
            orientationString = @"portrait";
            break;
        case HZMRAIDForceOrientationLandscape:
            orientationString = @"landscape";
            break;
        case HZMRAIDForceOrientationNone:
            orientationString = @"none";
            break;
        default:
            orientationString = @"wtf!";
            break;
    }
    
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat: @"%@ %@ %@ %@",
                      [self.class description],
                      NSStringFromSelector(_cmd),
                      (_orientationProperties.allowOrientationChange ? @"YES" : @"NO"),
                      orientationString]];

    _orientationProperties = orientationProps;
    UIInterfaceOrientation currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationPortrait) {
        if (UIInterfaceOrientationIsPortrait(currentInterfaceOrientation)) {
            // this will accomodate both portrait and portrait upside down
            _preferredOrientation = currentInterfaceOrientation;
        } else {
            _preferredOrientation = UIInterfaceOrientationPortrait;
        }
    } else if (_orientationProperties.forceOrientation == HZMRAIDForceOrientationLandscape) {
        if (UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) {
            // this will accomodate both landscape left and landscape right
            _preferredOrientation = currentInterfaceOrientation;
        } else {
            _preferredOrientation = UIInterfaceOrientationLandscapeLeft;
        }
    } else {
        // orientationProperties.forceOrientation == MRAIDForceOrientationNone
        if (_orientationProperties.allowOrientationChange) {
            UIDeviceOrientation currentDeviceOrientation = [[UIDevice currentDevice] orientation];
            // NB: UIInterfaceOrientationLandscapeLeft = UIDeviceOrientationLandscapeRight
            // and UIInterfaceOrientationLandscapeLeft = UIDeviceOrientationLandscapeLeft !
            if (currentDeviceOrientation == UIDeviceOrientationPortrait) {
                _preferredOrientation = UIInterfaceOrientationPortrait;
            } else if (currentDeviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
                _preferredOrientation = UIInterfaceOrientationPortraitUpsideDown;
            } else if (currentDeviceOrientation == UIDeviceOrientationLandscapeRight) {
                _preferredOrientation = UIInterfaceOrientationLandscapeLeft;
            } else if (currentDeviceOrientation == UIDeviceOrientationLandscapeLeft) {
                _preferredOrientation = UIInterfaceOrientationLandscapeRight;
            }
            
            // Make sure that the preferredOrientation is supported by the app. If not, then change it.
            
            NSString *preferredOrientationString;
            
            if (_preferredOrientation == UIInterfaceOrientationPortrait) {
                preferredOrientationString = @"UIInterfaceOrientationPortrait";
            } else if (_preferredOrientation == UIInterfaceOrientationPortraitUpsideDown) {
                preferredOrientationString = @"UIInterfaceOrientationPortraitUpsideDown";
            } else if (_preferredOrientation == UIInterfaceOrientationLandscapeLeft) {
                preferredOrientationString = @"UIInterfaceOrientationLandscapeLeft";
            } else if (_preferredOrientation == UIInterfaceOrientationLandscapeRight) {
                preferredOrientationString = @"UIInterfaceOrientationLandscapeRight";
            }
            
            NSArray *supportedOrientationsInPlist = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
            BOOL isSupported = [supportedOrientationsInPlist containsObject:preferredOrientationString];
            if (!isSupported) {
                // use the first supported orientation in the plist
                preferredOrientationString = supportedOrientationsInPlist[0];
                if ([preferredOrientationString isEqualToString:@"UIInterfaceOrientationPortrait"]) {
                    _preferredOrientation = UIInterfaceOrientationPortrait;
                } else if ([preferredOrientationString isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"]) {
                    _preferredOrientation = UIInterfaceOrientationPortraitUpsideDown;
                } else if ([preferredOrientationString isEqualToString:@"UIInterfaceOrientationLandscapeLeft"]) {
                    _preferredOrientation = UIInterfaceOrientationLandscapeLeft;
                } else if ([preferredOrientationString isEqualToString:@"UIInterfaceOrientationLandscapeRight"]) {
                    _preferredOrientation = UIInterfaceOrientationLandscapeRight;
                }
            }
        } else {
            // orientationProperties.allowOrientationChange == NO
            _preferredOrientation = currentInterfaceOrientation;
        }
    }
    
    [HZMRAIDLogger debug:@"MRAID - ModalViewController" withMessage:[NSString stringWithFormat:@"requesting from %@ to %@",
                            [self stringfromUIInterfaceOrientation:currentInterfaceOrientation],
                            [self stringfromUIInterfaceOrientation:_preferredOrientation]]];
    
    if ((_orientationProperties.forceOrientation == HZMRAIDForceOrientationPortrait && UIInterfaceOrientationIsPortrait(currentInterfaceOrientation)) ||
        (_orientationProperties.forceOrientation == HZMRAIDForceOrientationLandscape && UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) ||
        (_orientationProperties.forceOrientation == HZMRAIDForceOrientationNone && (_preferredOrientation == currentInterfaceOrientation)))
    {
        return;
    }
    
    UIViewController *presentingVC;
    if ([self respondsToSelector:@selector(presentingViewController)]) {
        // iOS 5+
        presentingVC = self.presentingViewController;
    } else {
        // iOS 4
        presentingVC = self.parentViewController;
    }
    
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)] &&
        [self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        // iOS 6+
        [self dismissViewControllerAnimated:NO completion:^{
             [presentingVC presentViewController:self animated:NO completion:nil];
         }];
    } else {
        // < iOS 6
        // Turn off the warning about using a deprecated method.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self dismissModalViewControllerAnimated:NO];
        [presentingVC presentModalViewController:self animated:NO];
#pragma clang diagnostic pop
    }
    
    _hasRotated = YES;
}

- (NSString *)stringfromUIInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            return @"portrait";
        case UIInterfaceOrientationPortraitUpsideDown:
            return @"portrait upside down";
        case UIInterfaceOrientationLandscapeLeft:
            return @"landscape left";
        case UIInterfaceOrientationLandscapeRight:
            return @"landscape right";
        default:
            return @"unknown";
    }
}

@end
