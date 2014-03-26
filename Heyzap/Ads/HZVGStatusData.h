//
//  HZVGStatusData.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@interface HZVGStatusData : HZClassProxy

typedef enum
{
    HZVGStatusOkay,
    HZVGStatusNetworkError,
    HZVGStatusDiskError
}   HZVGStatus;

@property(nonatomic, assign) HZVGStatus status;

@end
