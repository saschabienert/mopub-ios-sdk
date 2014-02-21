//
//  HZGenericPopup.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZGenericPopup.h"
#import "HZUtils.h"

@interface HZGenericPopup()
@property (nonatomic) UIInterfaceOrientation currentOrientation;

@end

@implementation HZGenericPopup

- (id)init
{
    self = [super init];
    if (self) {
        self.contentView = [[UIView alloc] initWithFrame:CGRectNull];
        [self addSubview:self.contentView];
    }
    return self;
}

- (void) layoutSubviews {
    [self adjustForOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
}

- (void) adjustForOrientation:(UIInterfaceOrientation)orientation {
    if (self.currentOrientation != orientation) {
        self.currentOrientation = orientation;
        [self sizeToFitOrientation: YES];
    }
}

- (void)sizeToFitOrientation:(BOOL)transform {
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // Presets
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    float statusBarOffset = 0.0;
    
    self.frame = frame;
    
    // Content View
    if (CGRectIsNull(self.contentView.frame)) {
        self.contentView.frame = CGRectMake(0, 0, 320, 300);
    }
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        self.contentView.center = CGPointMake((self.bounds.size.width)/2.0, (self.bounds.size.height - statusBarOffset)/2.0);
    } else {
        self.contentView.center = CGPointMake((self.bounds.size.width - statusBarOffset)/2.0, self.bounds.size.height/2.0);
    }
    
}

- (void) show {
    UIView *subview = [HZUtils windowOrNil];
    if (!subview) {
        return;
    }
    
    
    [self sizeToFitOrientation: YES];
//    self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
    [subview addSubview: self];
    
//    self.alpha = 0;
//    
//    [UIView animateWithDuration:0.5f
//                          delay:0
//                        options:UIViewAnimationOptionAllowUserInteraction
//                     animations:^{
//        self.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
//        self.alpha = 1;
//    }completion:^(BOOL finished){
//        [self sizeToFitOrientation: YES];
//    }];
  
    [UIView animateWithDuration:0.3/1.5 animations:^{
        self.transform = CGAffineTransformScale([self transformForOrientation], 1.0, 1.0);
    } completion:^(BOOL finished) {
        
    }];
  
    [UIView animateWithDuration:0.3/1.5 animations:^{
        self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                self.transform = [self transformForOrientation];
            } completion:^(BOOL finished) {
                [self sizeToFitOrientation: YES];
                [UIView animateWithDuration: 0.10 delay: 0.0  options: UIViewAnimationOptionCurveEaseIn animations:^{
                    self.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.5];
                } completion: nil];
            }];
        }];
    }];
}

- (void) dismissAnimated:(BOOL)animated completion:(void(^)(void))completion{
    if (animated) {
        [UIView animateWithDuration: 0.05 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
            self.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration: 0.1 animations:^{
                self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
            } completion:^(BOOL finished) {
                [self removeFromSuperview];
                completion ? completion() : nil;
            }];
        }];
    } else {
        [self removeFromSuperview];
        completion ? completion() : nil;
    }
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated completion:nil];
}

@end
