//
//  O_main_thread_host.m
//  DemoForPlayer
//
//  Created by user_admin on A/14/2014.
//  Copyright (c) 2014 darklinden. All rights reserved.
//

#import "O_main_thread_host.h"

typedef void(^WorkBlock)(void);

@interface O_work_holder : NSObject {
    WorkBlock _work;
}

@property (atomic, assign) WorkBlock work;
@end

@implementation O_work_holder

+ (id)holder:(WorkBlock)work
{
    O_work_holder *holder = [[O_work_holder alloc] init];
    holder.work = work;
    return holder;
}

- (void)setWork:(WorkBlock)work
{
    _work = work;
}

- (WorkBlock)work
{
    return _work;
}

@end

@interface O_main_thread_host () {
    WorkBlock _work;
}
@property (nonatomic, assign) BOOL          is_list_working;
@property (atomic,    strong) NSMutableArray   *work_list;
@end

@implementation O_main_thread_host

+ (id)host
{
    static __strong O_main_thread_host *host = nil;
    if (!host) {
        host = [[O_main_thread_host alloc] init];
        host.work_list = [NSMutableArray array];
    }
    return host;
}

#pragma mark - do on main
+ (void)do_on_main:(WorkBlock)work
{
    [[O_main_thread_host host] do_on_main:work];
}

- (void)do_on_main:(WorkBlock)work
{
    _work = work;
    
    if ([NSThread isMainThread]) {
        [self main_work];
    }
    else {
        [self performSelectorOnMainThread:@selector(main_work)
                               withObject:nil
                            waitUntilDone:YES];
    }
}

- (void)main_work
{
    if (_work) {
        _work();
    }
}

#pragma mark - do in main list

+ (void)do_in_main_list:(void (^)(void))work
{
    [[O_main_thread_host host] do_in_main_list:work];
}

- (void)do_in_main_list:(void (^)(void))work
{
    O_work_holder *holder = [O_work_holder holder:work];
    [self.work_list addObject:holder];
    
    if ([NSThread isMainThread]) {
        [self performSelector:@selector(main_list_work)
                   withObject:nil
                   afterDelay:0.0];
    }
    else {
        [self performSelectorOnMainThread:@selector(main_list_work)
                               withObject:nil
                            waitUntilDone:NO];
    }
}

- (void)main_list_work
{
    if (!_is_list_working) {
        [self performSelector:@selector(list_work)
                   withObject:nil
                   afterDelay:0.0];
    }
}

- (void)list_work
{
    _is_list_working = YES;
    if (!self.work_list.count) {
        _is_list_working = NO;
        return;
    }
    
    O_work_holder *holder = self.work_list.firstObject;
    if (holder.work) {
        holder.work();
    }
    
    [self.work_list removeObject:holder];
    
    if (self.work_list.count) {
        [self performSelector:@selector(main_list_work)
                   withObject:nil
                   afterDelay:0.0];
    }
    else {
        _is_list_working = NO;
    }
}

@end
