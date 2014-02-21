//
//  Header.h
//  Heyzap
//
//  Created by Maximilian Tagher on 8/12/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#ifdef DEBUG
#   define DLog(__FORMAT__, ...) NSLog(__FORMAT__, ##__VA_ARGS__)
#else
#   define DLog(...) do {} while (0)
#endif