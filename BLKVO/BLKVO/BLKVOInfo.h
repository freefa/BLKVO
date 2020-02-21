//
//  BLKVOInfo.h
//  BLKVO
//
//  Created by Louis.B on 2020/2/18.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+BLKVO.h"

@interface BLKVOInfo : NSObject

@property (nonatomic, weak) id observer;

@property (nonatomic) BLKVOChangeOptions options;

@property (nonatomic, copy) BLKVOHandler handler;

@property (nonatomic) void *context;

@end

