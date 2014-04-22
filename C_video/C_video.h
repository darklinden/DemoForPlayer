//
//  C_video.h
//  DemoForMultiStreamPlayer
//
//  Created by darklinden on 7/4/12.
//  Copyright (c) 2012 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMedia/CoreMedia.h>

#define Key_GroupContentsCount          @"Key_GroupContentsCount"
#define Key_GroupName                   @"Key_GroupName"
#define Key_GroupType                   @"Key_GroupType"
#define Key_GroupLogo                   @"Key_GroupLogo"
#define Key_GroupID                     @"Key_GroupID"
#define Key_VideoName                   @"Key_VideoName"
#define Key_VideoURL                    @"Key_VideoURL"

@interface O_item : NSObject
@property (nonatomic, assign) CMTimeRange time_range;
@property (nonatomic, strong) CALayer     *layer_watermark;

+ (id)item;

@end

@interface C_video : NSObject

+ (int64_t)video_length:(NSURL *)videoUrl;

+ (CMTimeRange)video_range:(NSURL *)videoUrl;

+ (CMTimeScale)video_fps:(NSURL *)videoUrl;

+ (void)set_thumb_image:(NSURL*)url
                in_view:(UIImageView *)imgV
                   size:(CGSize)maxSize;

+ (BOOL)extract_audio_from:(NSURL*)src
                        to:(NSURL*)des
                     error:(NSError **)error;

+ (BOOL)cut_video_src:(NSURL*)src
                  des:(NSURL*)des
                range:(CMTimeRange)range
           presetName:(NSString *)preset_name
       outputFileType:(NSString *)file_type
                error:(NSError **)error;

+ (NSArray *)split_video_src:(NSURL *)src
                   to_folder:(NSString *)folder_path
                      ranges:(NSArray *)ranges
                  presetName:(NSString *)preset_name
              outputFileType:(NSString *)file_type
               pathExtension:(NSString *)pathExtension
                       error:(NSError **)error;

+ (BOOL)stitch_videos:(NSArray *)videos
               ranges:(NSArray *)ranges
                  des:(NSURL*)des
           presetName:(NSString *)preset_name
       outputFileType:(NSString *)file_type
                error:(NSError **)error;

+ (NSMutableArray *)get_photo_groups;

+ (NSMutableArray *)get_videos;

+ (BOOL)export_assetUrl:(NSURL *)assetUrl
              to_folder:(NSString *)folderPath
                  error:(NSError **)error;

+ (BOOL)watermark_video_src:(NSURL *)src
                        des:(NSURL *)des
                  markLayer:(CALayer *)mark_layer
                 presetName:(NSString *)preset_name
             outputFileType:(NSString *)file_type
                      range:(O_item **)item_range
                      error:(NSError **)error;

+ (BOOL)watermark_video_src:(NSURL *)src
                        des:(NSURL *)des
                      marks:(NSArray *)marks
                 presetName:(NSString *)preset_name
             outputFileType:(NSString *)file_type
                      error:(NSError **)error;

@end
