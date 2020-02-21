//
//  KVOViewController.m
//  BLKVO
//
//  Created by Louis.B on 2020/2/20.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import "KVOViewController.h"
#import "Person.h"
#import "NSObject+BLKVO.h"
#import <objc/runtime.h>

@interface KVOViewController ()

@property (nonatomic, strong) Person *person;

@property (nonatomic, strong) NSMutableArray *names;

@end

@implementation KVOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KVO Test";
    self.names = @[@"Jack", @"Rose", @"John", @"Alex"].mutableCopy;
    self.person = [[Person alloc] init];
    
    [self printClasses:[Person class]];
    [self printMethods:[self.person class]];
    
    [self.person addObserver:self
                  forKeyPath:@"name"
                     options:BLKVOChangeOptionNew
                     context:NULL
               changeHandler:^(NSDictionary *change, void *context) {
        NSLog(@"change: %@", change);
    }];
    
    [self printClasses:[Person class]];
    [self printMethods:NSClassFromString(@"BLKVOClass_Person")];
}

- (IBAction)kvoButtonTouched:(id)sender {
    static NSInteger _nameIndex = 0;
    self.person.name = self.names[_nameIndex];
    _nameIndex++;
    if (_nameIndex >= self.names.count) {
        _nameIndex = 0;
    }
    
//    [self.person addObserver:self
//                  forKeyPath:@"name"
//                     options:BLKVOChangeOptionNew
//                     context:NULL
//               changeHandler:^(NSDictionary *change, void *context) {
//        NSLog(@"change: %@", change);
//    }];
}

/// 打印出指定类及其子类列表
- (void)printClasses:(Class)cls {
    int count = objc_getClassList(NULL, 0);
    NSMutableArray *results = [NSMutableArray arrayWithObject:cls];
    Class *classes = (Class *)malloc(sizeof(Class) * count);
    objc_getClassList(classes, count);
    for (int i = 0; i < count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [results addObject:classes[i]];
        }
    }
    NSLog(@"\nClasses: %@", results);
    free(classes);
}

/// 打印出指定类所有的方法
- (void)printMethods:(Class)cls {
    unsigned int count = 0;
    Method *methodList = class_copyMethodList(cls, &count);
    printf("Methods of class: %s (\n", NSStringFromClass(cls).UTF8String);
    for (int i = 0; i < count; i++) {
        Method method = methodList[i];
        SEL sel = method_getName(method);
        IMP imp = method_getImplementation(method);
        printf("    %s-%p\n", NSStringFromSelector(sel).UTF8String, imp);
    }
    printf(")\n");
    free(methodList);
}

@end
