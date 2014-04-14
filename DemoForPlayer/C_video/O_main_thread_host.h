//
//  O_main_thread_host.h
//  DemoForPlayer
//
//  Created by user_admin on A/14/2014.
//  Copyright (c) 2014 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface O_main_thread_host : NSObject

+ (void)do_on_main:(void(^)(void))work;
+ (void)do_in_main_list:(void(^)(void))work;

@end
