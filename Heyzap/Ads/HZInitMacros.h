//
//  HZInitMacros.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#define CHECK_NOT_NIL(value,name) do { \
if (value == nil) { \
*error = [NSError errorWithDomain:@"heyzap" code:3 userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: @"Missing value: %@",name]}]; \
return nil; \
} \
} while (0)


