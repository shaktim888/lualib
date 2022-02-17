//
//  LSCPointer.m
//  LuaScriptCore
//
//  Created by admin on 16/10/27.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LSCPointer.h"
#import "LSCManagedObjectProtocol.h"
#import "LSCContext_Private.h"
#import "LSCSession_Private.h"
#import "LSCEngineAdapter.h"

@interface LSCPointer () <LSCManagedObjectProtocol>

typedef void(^FreeBlockType)(void);

@property (nonatomic) LSCUserdataRef userdataRef;

/**
 是否需要释放内存，对于传入原始指针的构造方法会为指针包装一层LSCPointerRef结构体，因此，在对象释放时需要进行释放LSCPointerRef结构体。
 */
 @property (nonatomic) BOOL needFree;

 @property (nonatomic, strong) NSMutableArray<FreeBlockType>* freeBlocks;

/**
 连接标识
 */
@property (nonatomic, copy) NSString *_linkId;


@end

@implementation LSCPointer

- (instancetype)initWithUserdata:(LSCUserdataRef)ref
{
    if (self = [super init])
    {
        self.needFree = NO;
        self.userdataRef = ref;
        self.freeBlocks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithPtr:(const void *)ptr
{
    if (self = [super init])
    {
        self.needFree = YES;
        self.userdataRef = malloc(sizeof(LSCUserdataRef));
        self.freeBlocks = [[NSMutableArray alloc] init];
        self.userdataRef -> value = (void *)ptr;
    }
    return self;
}

- (void)dealloc
{
    if(self.freeBlocks.count > 0)
    {
        for(FreeBlockType p in self.freeBlocks) {
            p();
        }
        [self.freeBlocks removeAllObjects];
    }
    if (self.needFree)
    {
        free(self.userdataRef);
        self.userdataRef = NULL;
    }
}

- (const LSCUserdataRef)dataref
{
    return self.userdataRef;
}

#pragma mark - LSCManagedObjectProtocol

- (NSString *)linkId
{
    if (!self._linkId)
    {
        self._linkId = [NSString stringWithFormat:@"%p", [self dataref]->value];
    }
    
    return self._linkId;
}

- (BOOL)pushWithContext:(LSCContext *)context
{
    [self pushWithState:context.currentSession.state queue:context.optQueue exchanger:context.dataExchanger];
    return YES;
}

- (BOOL)pushWithState:(lua_State *)state queue:(LSCOperationQueue *)queue  exchanger:(LSCDataExchanger*) exchanger
{
    __weak typeof(self) thePointer = self;
    NSString * objectId = [NSString stringWithFormat:@"%p", [self dataref]->value];
    [self.freeBlocks addObject:^{
        [exchanger removeVar:objectId];
    }];
    void (^handler) (void) = ^{
        // 一旦交给了lua。就不再拥有释放权才对
        // 内存泄漏
        [LSCEngineAdapter pushLightUserdata:[thePointer dataref] state:state];
    };
    
    if (queue)
    {
        [queue performAction:handler];
    }
    else
    {
        handler ();
    }
    
    return YES;
}

@end
