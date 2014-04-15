//
//  V_player.m
//  DemoForMultiStreamPlayer
//
//  Created by darklinden DarkLinden on 7/3/12.
//  Copyright (c) 2012 darklinden. All rights reserved.
//

#import "V_player.h"

@implementation V_player

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)play:(NSURL *)url
{
    AVPlayer *player = [[AVPlayer alloc] initWithURL:url];
    [self setPlayer:player];
    [player play];
}

- (AVPlayer*)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)removeFromSuperview
{
    [self setPlayer:nil];
    [super removeFromSuperview];
}

@end
