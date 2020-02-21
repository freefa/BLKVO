//
//  NSObject+BLKVOMethod.h
//  BLKVO
//
//  Created by Louis.B on 2020/2/18.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+BLKVO.h"

@interface NSObject (BLKVOIMP)

// 根据keyPath获取setter方法名
- (NSString *)setterForKeyPath:(NSString *)keyPath;

// 根据setter方法名获取keyPath
- (NSString *)keyPathForSetter:(NSString *)setter;

// 判断方法是否存在
- (BOOL)isMethodExist:(NSString *)selName;

// 创建KVO子类
- (void)createKVOSubclassIfNotExist;

// isa-swizzling
- (void)makeIsaSwizzling;

// 重写-class方法
- (void)addCommonKVOMethods;

// 重写setter
- (void)overrideSetterForKeyPath:(NSString *)keyPath;

// 保存观察者信息
- (void)saveObserver:(id)observer
          forKeyPath:(NSString *)keyPath
             options:(BLKVOChangeOptions)options
             context:(void *)context
             handler:(BLKVOHandler)handler;

// 移除观察者
- (void)bl_removeObserver:(id)observer
               forKeyPath:(NSString *)keyPath
                  context:(void *)context;

@end
