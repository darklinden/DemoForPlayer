//
//  V_player.h
//  DemoForMultiStreamPlayer
//
//  Created by darklinden DarkLinden on 7/3/12.
//  Copyright (c) 2012 darklinden. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface V_player : UIView
- (void)play:(NSURL *)url;
- (AVPlayer*)player;
- (void)setPlayer:(AVPlayer *)player;
@end
