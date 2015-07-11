//
//  HZOpenRTBConnectionType.h
//  Heyzap
//
//  Created by Monroe Ekilah on 7/1/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

//the values below are expected server side, so be careful when changing them.
//table 6.10 of http://www.iab.net/media/file/OpenRTBAPISpecificationVersion2_2.pdf
typedef NS_ENUM(NSUInteger, HZOpenRTBConnectionType){
    HZOpenRTBConnectionTypeUnknown          = 0,
    HZOpenRTBConnectionTypeEthernet         = 1,
    HZOpenRTBConnectionTypeWifi             = 2,
    HZOpenRTBConnectionTypeCellularUnknown  = 3,
    HZOpenRTBConnectionTypeCellular2G       = 4,
    HZOpenRTBConnectionTypeCellular3G       = 5,
    HZOpenRTBConnectionTypeCellular4G       = 6,
};