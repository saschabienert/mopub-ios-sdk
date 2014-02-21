//
//  ShadowGradientLayer.h
//  Heyzap
//
//  Created by Daniel Rhodes on 4/4/13.
//
//

#import <QuartzCore/QuartzCore.h>

@interface HZShadowGradientLayer : CAGradientLayer
@property CGColorRef innerShadowColor;
@property CGSize innerShadowOffset;
@property CGFloat innerShadowRadius;
@property CGFloat innerShadowOpacity;
@end
