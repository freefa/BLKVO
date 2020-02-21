//
//  NSObject+BLKVO.h
//  BLKVO
//
//  Created by Louis.B on 2020/2/17.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import <Foundation/Foundation.h>

// 回调Block定义
typedef void(^BLKVOHandler)(NSDictionary *change, void *context);

typedef NS_OPTIONS(NSInteger, BLKVOChangeOptions) {
    BLKVOChangeOptionNew = 1 << 0,
    BLKVOChangeOptionOld = 1 << 1
};

typedef NSString * BLKVOChangeKey NS_STRING_ENUM;

// 回调中字典的key定义
extern BLKVOChangeKey const BLKVOChangeNewKey;
extern BLKVOChangeKey const BLKVOChangeOldKey;

@interface NSObject (BLKVO)

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(BLKVOChangeOptions)options
            context:(void *)context
      changeHandler:(BLKVOHandler)handler;

- (void)removeKvoObserver:(id)observer;

- (void)removeKvoObserver:(id)observer forKeyPath:(NSString *)keyPath;

- (void)removeKvoObserver:(id)observer
               forKeyPath:(NSString *)keyPath
                  context:(void *)context;
@end
