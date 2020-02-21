//
//  NSObject+BLKVOMethod.m
//  BLKVO
//
//  Created by Louis.B on 2020/2/18.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import "NSObject+BLKVOIMP.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "BLKVOInfo.h"

NSString * const BLKVO_CLASS_PREFIX = @"BLKVOClass_";

const char * BLKVO_ASSOCIATION_INFO = "BLKVO_ASSOSIATION_INFO";

@implementation NSObject (BLKVOIMP)

#pragma mark - interface
- (NSString *)setterForKeyPath:(NSString *)keyPath {
    // setKeyPath / _setKeyPath / setIsKeyPath
    
    unsigned int count = 0;
    Method *methodList = class_copyMethodList([self class], &count);
    NSArray *possibleSetters = [self possibleSettersForKeyPath:keyPath];
    for (int i = 0; i < count; i++) {
        Method method = methodList[i];
        SEL methodSel = method_getName(method);
        NSString *setter = NSStringFromSelector(methodSel);
        if ([possibleSetters containsObject:setter]) {
            free(methodList);
            NSLog(@"%s: find setter = %@", __func__, setter);
            return setter;
        }
    }
    free(methodList);
    NSLog(@"%s: does not find setter for keyPath: %@", __func__, keyPath);
    return nil;
}

- (NSString *)keyPathForSetter:(NSString *)setter {
    if (NO == [setter hasSuffix:@":"]) {
        NSLog(@"%s: illegal setter: %@", __func__, setter);
        return nil;
    }
    
    NSString *prefix = nil;
    for (NSString *pf in [self setterPrefixes]) {
        if ([setter hasPrefix:pf]) {
            prefix = pf;
            break;
        }
    }
    
    if (nil == prefix) {
        NSLog(@"%s: illegal setter prefix: %@", __func__, setter);
        return nil;
    }
    
    NSRange range = NSMakeRange(prefix.length, setter.length - prefix.length - 1);
    NSString *keyPath = [setter substringWithRange:range];
    NSString *firstLetter = [[keyPath substringToIndex:1] lowercaseString];
    NSString *tailLetters = [keyPath substringFromIndex:1];
    keyPath = [NSString stringWithFormat:@"%@%@", firstLetter, tailLetters];
    NSLog(@"%s: keyPath = %@", __func__, keyPath);
    return keyPath;
}

- (BOOL)isMethodExist:(NSString *)selName {
    unsigned int count = 0;
    Class cls = object_getClass(self);
    Method *methodList = class_copyMethodList(cls, &count);
    for (int i = 0; i < count; i++) {
        Method method = methodList[i];
        if ([selName isEqualToString:NSStringFromSelector(method_getName(method))]) {
            return YES;
        }
    }
    return NO;
}

- (void)createKVOSubclassIfNotExist {
    NSString *kvoClsName = [self KVOClassName];
    Class cls = NSClassFromString(kvoClsName);
    if (nil == cls) {
        Class cls = objc_allocateClassPair([self class], kvoClsName.UTF8String, 0);
        objc_registerClassPair(cls);
        NSLog(@"register cls: %@", cls);
    } else {
        NSLog(@"kvo cls is already exist, don't need create");
    }
}

- (void)makeIsaSwizzling {
    NSString *kvoClsName = [self KVOClassName];
    object_setClass(self, NSClassFromString(kvoClsName));
}

- (void)addCommonKVOMethods {
    // BLKVOClass_Xxxxxx
    Class kvoCls = NSClassFromString([self KVOClassName]);
    
    // -class
    NSString *clsMethodName = @"class";
    if (NO == [self isMethodExist:clsMethodName]) {
        SEL classSel = NSSelectorFromString(@"class");
        Method method = class_getInstanceMethod([NSObject class], classSel);
        BOOL suc = class_addMethod(kvoCls,
                                   classSel,
                                   (IMP)bl_class,
                                   method_getTypeEncoding(method));
        NSLog(@"add \"class\" method %@", suc ? @"success" : @"failed");
    } else {
        NSLog(@"\"class\" method alread exist");
    }
}

- (void)overrideSetterForKeyPath:(NSString *)keyPath {
    NSString *setterName = [self setterForKeyPath:keyPath];
    if ([self isMethodExist:setterName]) {
        NSLog(@"\"%@\" is already exist", setterName);
        return;
    }
    
    SEL setterSel = NSSelectorFromString(setterName);
    Method method = class_getInstanceMethod([self class], setterSel);
    Class cls = NSClassFromString([self KVOClassName]);
    class_addMethod(cls, setterSel, (IMP)bl_setter, method_getTypeEncoding(method));
}

- (void)saveObserver:(id)observer
          forKeyPath:(NSString *)keyPath
             options:(BLKVOChangeOptions)options
             context:(void *)context
             handler:(BLKVOHandler)handler {
    BLKVOInfo *info = [[BLKVOInfo alloc] init];
    info.observer = observer;
    info.options = options;
    info.handler = handler;
    info.context = context;
    NSMutableArray *array = [self savedObserverInfosForKeyPath:keyPath];
    for (BLKVOInfo *model in array) {
        if ([model.observer isEqual:observer] && model.context == context) {
            NSLog(@"Already has the same observer");
            return;
        }
    }
    [array addObject:info];
}

- (void)bl_removeObserver:(id)observer
               forKeyPath:(NSString *)keyPath
                  context:(void *)context {
    NSMutableDictionary *info = [self savedObserverInfo];
    NSArray *keyArray = [info allKeys];
    
    if (nil == observer) {
        // 移除当前对象的所有观察者
        for (NSString *key in keyArray) {
            NSMutableArray<BLKVOInfo *> *infos = info[key];
            for (int i = 0; i < infos.count; i++) {
                BLKVOInfo *model = infos[i];
                model.handler = nil;
                [infos removeObject:model];
            }
        }
        return;
    }
    
    if (nil == keyPath && NULL == context) {
        // 移除当前对象的指定观察者
        for (NSString *key in keyArray) {
            NSMutableArray<BLKVOInfo *> *infos = info[key];
            for (int i = 0; i < infos.count; i++) {
                BLKVOInfo *model = infos[i];
                if ([model.observer isEqual:observer]) {
                    model.handler = nil;
                    [infos removeObject:model];
                }
            }
        }
        return;
    }
    
    // 移除当前对象的指定观察者，指定keyPath，指定context
    if (nil != keyPath) {
        NSMutableArray<BLKVOInfo *> *infos = info[keyPath];
        for (int i = 0; i < infos.count; i++) {
            BLKVOInfo *model = infos[i];
            if ([model.observer isEqual:observer]) {
                if (NULL != context) {
                    if (context == model.context) {
                        model.handler = nil;
                        [infos removeObject:model];
                    }
                } else {
                    model.handler = nil;
                    [infos removeObject:model];
                }
            }
        }
    } else if (NULL != context) {
        for (NSString *key in keyArray) {
            NSMutableArray<BLKVOInfo *> *infos = info[key];
            for (int i = 0; i < infos.count; i++) {
                BLKVOInfo *model = infos[i];
                if ([model.observer isEqual:observer] && context == model.context) {
                    model.handler = nil;
                    [infos removeObject:model];
                }
            }
        }
    }
}

#pragma mark -- private
- (NSArray<NSString *> *)setterPrefixes {
    static NSArray *_setterPrefixes = nil;
    if (_setterPrefixes == nil) {
        _setterPrefixes = @[@"set", @"_set", @"setIs"];
    }
    return _setterPrefixes;
}

- (NSArray<NSString *> *)possibleSettersForKeyPath:(NSString *)keyPath {
    NSArray *prefixes = [self setterPrefixes];
    NSMutableArray *setters = [NSMutableArray arrayWithCapacity:prefixes.count];
    
    NSString *firstLetter = [keyPath substringToIndex:1];
    NSString *tailLetters = [keyPath substringFromIndex:1];
    NSString *suffix = [[[firstLetter uppercaseString] stringByAppendingString:tailLetters] stringByAppendingString:@":"];
    for (NSString *prf in prefixes) {
        NSString *setter = [prf stringByAppendingString:suffix];
        [setters addObject:setter];
    }
    
    return setters;
}

- (NSString *)KVOClassName {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName hasPrefix:BLKVO_CLASS_PREFIX]) {
        return clsName;
    }
    NSString *kvoClsName = [NSString stringWithFormat:@"%@%@", BLKVO_CLASS_PREFIX, clsName];
    return kvoClsName;
}

- (NSMutableDictionary *)savedObserverInfo {
    NSMutableDictionary *info = objc_getAssociatedObject(self, BLKVO_ASSOCIATION_INFO);
    if (nil == info) {
        info = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self,
                                 BLKVO_ASSOCIATION_INFO,
                                 info,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return info;
}

- (NSMutableArray *)savedObserverInfosForKeyPath:keyPath {
    NSMutableDictionary *info = [self savedObserverInfo];
    NSMutableArray *array = info[keyPath];
    if (nil == array) {
        array = [NSMutableArray array];
        info[keyPath] = array;
    }
    return array;
}

Class bl_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

- (void)bl_dealloc {
    // 当前对象销毁：1.移除所有观察者；2.销毁关联对象；3.调用系统dealloc
    Class cls = object_getClass(self);
    NSString *clsName = NSStringFromClass(cls);
    if ([clsName hasPrefix:BLKVO_CLASS_PREFIX]) {
        printf("%s: clean KVO info\n", __func__);
        
        [self removeKvoObserver:nil forKeyPath:nil context:NULL];
        
        objc_setAssociatedObject(self,
                                 BLKVO_ASSOCIATION_INFO,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
        // isa指回原类（对象销毁了，指不指回原类其实也无所谓）
        Class superCls = class_getSuperclass(object_getClass(self));
        object_setClass(self, superCls);
    }
    
    // Call system -dealloc
    [self bl_dealloc];
}

static void bl_setter(id self, SEL _cmd, id newValue) {
    NSString *setter = NSStringFromSelector(_cmd);
    NSString *keyPath = [self keyPathForSetter:setter];
    
    NSMutableDictionary *change = [NSMutableDictionary dictionaryWithCapacity:2];
    id oldValue = [self valueForKey:keyPath];
    if (nil != oldValue) {
        change[BLKVOChangeOldKey] = oldValue;
    }
    
    // call super setter
    SEL superSetter = NSSelectorFromString(setter);
    struct objc_super superMsg = {
        .receiver = self,
        .super_class = [self class]
    };
    void (*bl_msgSendSuper)(void *, SEL , id) = (void *)objc_msgSendSuper;
    bl_msgSendSuper(&superMsg, superSetter, newValue);
    
    if (nil != newValue) {
        change[BLKVOChangeNewKey] = newValue;
    }
    
    NSArray *array = [self savedObserverInfosForKeyPath:keyPath];
    for (BLKVOInfo *model in array) {
        if (nil != model.handler) {
            model.handler(change, model.context);
        }
    }
}

#pragma mark - class method
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self bl_exchangeInstanceIMP:NSSelectorFromString(@"dealloc")
                      newInstanceIMP:@selector(bl_dealloc)];
    });
}

+ (BOOL)bl_exchangeInstanceIMP:(SEL)orgSEL newInstanceIMP:(SEL)swizzledSEL {
    Class cls = self;
    Method orgMethod = class_getInstanceMethod(cls, orgSEL);
    Method swiMethod = class_getInstanceMethod(cls, swizzledSEL);
    
    if (NULL == swiMethod) {
        return NO;
    }
    
    if (NULL == orgMethod) {
        class_addMethod(cls,
                        orgSEL,
                        method_getImplementation(swiMethod),
                        method_getTypeEncoding(swiMethod));
        
        method_setImplementation(swiMethod,
                                 imp_implementationWithBlock(^(id self, SEL _cmd){ }));
    }
    
    BOOL didAddMethod = class_addMethod(cls,
                                        orgSEL,
                                        method_getImplementation(swiMethod),
                                        method_getTypeEncoding(swiMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSEL,
                            method_getImplementation(orgMethod),
                            method_getTypeEncoding(orgMethod));
    } else {
        method_exchangeImplementations(orgMethod, swiMethod);
    }
    return YES;
}

@end
