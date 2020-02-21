//
//  NSObject+BLKVO.m
//  BLKVO
//
//  Created by Louis.B on 2020/2/17.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import "NSObject+BLKVO.h"
#import "NSObject+BLKVOIMP.h"

BLKVOChangeKey const BLKVOChangeNewKey = @"New";
BLKVOChangeKey const BLKVOChangeOldKey = @"Old";

@implementation NSObject (BLKVO)

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(BLKVOChangeOptions)options
            context:(void *)context
      changeHandler:(BLKVOHandler)handler {
    
    // 1.入参检查
    if (nil == observer || nil == keyPath || 0 == keyPath.length || 0 == options || nil == handler) {
        return;
    }
    
    // 2.检查是否有setter
    NSString *setter = [self setterForKeyPath:keyPath];
    if (NO == [self isMethodExist:setter]) {
        NSLog(@"no setter method in origin class: %@", [self class]);
        return;
    }
    
    // 3.动态创建子类BLKVOClass_xxx
    [self createKVOSubclassIfNotExist];
    
    // 4.isa-swizzling
    [self makeIsaSwizzling];
    
    // 5.重写-class、-dealloc、添加-_isKVOA方法
    [self addCommonKVOMethods];
    
    // 6.重写setter
    [self overrideSetterForKeyPath:keyPath];
    
    // 7.保存观察者信息
    [self saveObserver:self
            forKeyPath:keyPath
               options:options
               context:context
               handler:handler];
}

- (void)removeKvoObserver:(id)observer {
    [self removeKvoObserver:observer forKeyPath:nil];
}

- (void)removeKvoObserver:(id)observer forKeyPath:(NSString *)keyPath {
    [self removeKvoObserver:observer forKeyPath:keyPath context:NULL];
}

- (void)removeKvoObserver:(id)observer
               forKeyPath:(NSString *)keyPath
                  context:(void *)context {
    [self bl_removeObserver:observer forKeyPath:keyPath context:context];
}

@end
