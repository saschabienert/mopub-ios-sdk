//
//  HZFBAdImage.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/27/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@interface HZFBAdImage : HZClassProxy

@property (nonatomic, copy, readonly, nonnull) NSURL *url;
/*!
 @property
 @abstract Typed access to the image width.
 */
@property (nonatomic, assign, readonly) NSInteger width;
/*!
 @property
 @abstract Typed access to the image height.
 */
@property (nonatomic, assign, readonly) NSInteger height;

@end
