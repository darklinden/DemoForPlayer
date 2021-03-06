//
//  C_video.m
//  DemoForMultiStreamPlayer
//
//  Created by darklinden on 7/4/12.
//  Copyright (c) 2012 darklinden. All rights reserved.
//

#import "C_video.h"

#if !__has_feature(objc_arc)
#error 请在ARC下编译此类。
#endif

@implementation O_item

+ (id)item
{
    O_item *mark = [[O_item alloc] init];
    return mark;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ range_start:%lf range_duration:%lf layer:%@>", [self class], CMTimeGetSeconds(self.time_range.start), CMTimeGetSeconds(self.time_range.duration), self.layer_watermark];
}

@end

@interface C_video ()

@end

@implementation C_video

+ (int64_t)video_length:(NSURL *)videoUrl
{
    int64_t length = 0;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    length = (int64_t)(asset.duration.value / asset.duration.timescale);
    asset = nil;
    return length;
}

+ (CMTimeRange)video_range:(NSURL *)videoUrl
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    return CMTimeRangeMake(kCMTimeZero, asset.duration);
}

+ (CMTimeScale)video_fps:(NSURL *)videoUrl
{
#warning return 30 for default
    return 30;
    
    CMTimeScale time_scale = 0;
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetTrack *track_src = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    if (track_src) {
        time_scale = track_src.nominalFrameRate;
    }
    
    if (time_scale == 0) {
        time_scale = 30;
    }
    
    return time_scale;
}

+ (void)set_thumb_image:(NSURL*)url
                in_view:(UIImageView *)imgV
                   size:(CGSize)maxSize
{
    __block AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    __block AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *err){
        asset = nil, generator = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result != AVAssetImageGeneratorSucceeded) {
                NSLog(@"setThumbImage failed with error %@", err);
            }
            else {
                [imgV setImage:[UIImage imageWithCGImage:im]];
            }
        });
    };
    
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
}

+ (BOOL)extract_audio_from:(NSURL*)src
                        to:(NSURL*)des
                     error:(NSError **)error
{
    __block BOOL isDone = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[des path]])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:[des path] error:error]) {
            return NO;
        }
    }
    
	AVMutableComposition *composition = [AVMutableComposition composition];
    
    __block AVURLAsset * sourceAsset = [[AVURLAsset alloc] initWithURL:src options:nil];
    
    for (AVAssetTrack *track in [sourceAsset tracks]) {
        if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
            AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:track.mediaType preferredTrackID:kCMPersistentTrackID_Invalid];
            if (![compositionTrack insertTimeRange:track.timeRange
                                           ofTrack:track
                                            atTime:kCMTimeZero
                                             error:error]) {
                sourceAsset = nil;
                return NO;
            }
            compositionTrack.preferredTransform = track.preferredTransform;
        }
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
	
    exporter.outputURL = des;
    exporter.outputFileType = AVFileTypeAppleM4A;
	
    __block BOOL success = NO;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            success = YES;
        }
        
        NSError *err = [exporter error];
        
        if (err) {
            *error = err;
            NSLog(@"export error: %@", err);
        }
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    exporter = nil;
    
    return success;
}

+ (BOOL)cut_video_src:(NSURL*)src
                  des:(NSURL*)des
                range:(CMTimeRange)range
           presetName:(NSString *)preset_name
       outputFileType:(NSString *)file_type
                error:(NSError **)error
{
    __block BOOL isDone = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[des path]])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:[des path] error:error]) {
            return NO;
        }
    }
    
	AVMutableComposition *composition = [AVMutableComposition composition];
    
    __block AVURLAsset * sourceAsset = [[AVURLAsset alloc] initWithURL:src options:nil];
    
    for (AVAssetTrack *track in [sourceAsset tracks]) {
        AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:track.mediaType preferredTrackID:kCMPersistentTrackID_Invalid];
        if (![compositionTrack insertTimeRange:range
                                       ofTrack:track
                                        atTime:kCMTimeZero
                                         error:error]) {
            sourceAsset = nil;
            return NO;
        }
        compositionTrack.preferredTransform = track.preferredTransform;
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:preset_name];
	
    exporter.outputURL = des;
	
    exporter.outputFileType = file_type;
    
    __block BOOL success = NO;
	
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            success = YES;
        }
        
        NSError *err = [exporter error];
        
        if (err) {
            *error = err;
            NSLog(@"export error: %@", err);
        }
        
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    exporter = nil;
    
    return success;
}

+ (NSArray *)split_video_src:(NSURL *)src
                   to_folder:(NSString *)folder_path
                      ranges:(NSArray *)ranges
                  presetName:(NSString *)preset_name
              outputFileType:(NSString *)file_type
               pathExtension:(NSString *)pathExtension
                       error:(NSError **)error
{
    BOOL sucess = YES;
    
    [[NSFileManager defaultManager] removeItemAtPath:folder_path error:nil];
    if (![[NSFileManager defaultManager] createDirectoryAtPath:folder_path
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:error]) {
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < ranges.count; i++) {
        O_item *item_range = ranges[i];
        NSString *des = [folder_path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.%@", i, pathExtension]];
        sucess = [self cut_video_src:src
                                 des:[NSURL fileURLWithPath:des]
                               range:item_range.time_range
                          presetName:preset_name
                      outputFileType:file_type
                               error:error];
        if (sucess) {
            [array addObject:des];
        }
        else {
            array = nil;
            [[NSFileManager defaultManager] removeItemAtPath:folder_path error:nil];
            break;
        }
    }
    
    return [NSArray arrayWithArray:array];
}

+ (BOOL)stitch_videos:(NSArray *)videos
               ranges:(NSArray *)ranges
                  des:(NSURL*)des
           presetName:(NSString *)preset_name
       outputFileType:(NSString *)file_type
                error:(NSError **)error
{
    __block BOOL isDone = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[des path]])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:[des path] error:error]) {
            return NO;
        }
    }
    
	AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *videoTrack =
    [composition
     addMutableTrackWithMediaType:AVMediaTypeVideo
     preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *audioTrack =
    [composition
     addMutableTrackWithMediaType:AVMediaTypeAudio
     preferredTrackID:kCMPersistentTrackID_Invalid];
    
    for (int i = 0; i < videos.count; i++) {
        NSURL *src = videos[i];
        AVURLAsset * sourceAsset = [[AVURLAsset alloc] initWithURL:src options:nil];
        
        O_item *item = ranges[i];
        CMTimeRange range = item.time_range;
        range = CMTimeRangeMake(CMTimeMake(0, range.duration.timescale), CMTimeMake(range.duration.value - 2, range.duration.timescale));
        
        for (AVAssetTrack *track in [sourceAsset tracks]) {
            if ([track.mediaType isEqualToString:AVMediaTypeAudio]) {
                if (![audioTrack insertTimeRange:range
                                         ofTrack:track
                                          atTime:kCMTimeInvalid
                                           error:error]) {
                    sourceAsset = nil;
                    return NO;
                }
            }
            else if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                if (![videoTrack insertTimeRange:range
                                         ofTrack:track
                                          atTime:kCMTimeInvalid
                                           error:error]) {
                    sourceAsset = nil;
                    return NO;
                }
                videoTrack.preferredTransform = track.preferredTransform;
            }
            else {
                NSLog(@"media type unknown: %@", track.mediaType);
            }
        }
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:preset_name];
	
    exporter.outputURL = des;
	
    exporter.outputFileType = file_type;
    
    __block BOOL success = NO;
	
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            success = YES;
        }
        
        NSError *err = [exporter error];
        
        if (err) {
            *error = err;
            NSLog(@"export error: %@", err);
        }
        
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    exporter = nil;
    
    return success;
}

+ (NSMutableArray *)get_photo_groups
{
    __block BOOL isDone = NO;
    __block NSMutableArray *pArr_groups = [NSMutableArray array];
    ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *myerror){
        isDone = YES;
    };
    
    ALAssetsLibraryGroupsEnumerationResultsBlock libraryGroupsEnumeration =  ^(ALAssetsGroup *group, BOOL *stop) {  
        if (group) {
            if ([group numberOfAssets] > 0)
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                [dict setObject:[NSString stringWithFormat:@"%d", [group numberOfAssets]] forKey:Key_GroupContentsCount];
                [dict setObject:[NSString stringWithFormat:@"%@", [group valueForProperty:ALAssetsGroupPropertyName]] forKey:Key_GroupName];
                [dict setObject:[NSString stringWithFormat:@"%@",[group valueForProperty:ALAssetsGroupPropertyType]] forKey:Key_GroupType];
                [dict setObject:UIImageJPEGRepresentation([UIImage imageWithCGImage:group.posterImage],1) forKey:Key_GroupLogo];
                [dict setObject:[NSString stringWithFormat:@"%@", [group valueForProperty:ALAssetsGroupPropertyPersistentID]] forKey:Key_GroupID];
                [pArr_groups addObject:dict];
            }
        }
        else {
            isDone = YES;
        }
    };
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:libraryGroupsEnumeration
                         failureBlock:failureblock];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    library = nil;
    
    return [NSMutableArray arrayWithArray:pArr_groups];
}

+ (NSMutableArray *)get_videos
{
    __block BOOL isDone = NO;
    __block NSMutableArray *pArr_videos = [NSMutableArray array];
    
    ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *myerror){
        isDone = YES;
    };
    
    ALAssetsGroupEnumerationResultsBlock groupEnumeration = 
    ^(ALAsset *result, NSUInteger index, BOOL *stop){
        if (result != NULL) {
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                
                ALAssetRepresentation* representation = [result defaultRepresentation];
                [dict setObject:[representation filename] forKey:Key_VideoName];
                
                NSDictionary *urldict = [result valueForProperty:ALAssetPropertyURLs];
                NSArray *array = [urldict allKeys];
                if ([array count] > 0) {
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [urldict objectForKey:[array lastObject]]]];
                    [dict setObject:url forKey:Key_VideoURL];
                }
                
                    
                [pArr_videos addObject:dict];
            }
        }
        else {
//            NSLog(@"groupEnumeration result null");
        }
    };
    
    ALAssetsLibraryGroupsEnumerationResultsBlock libraryGroupsEnumeration = 
    ^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            NSInteger numberOfAssets = [group numberOfAssets];
            if (numberOfAssets > 0) {
                [group enumerateAssetsUsingBlock:groupEnumeration];
            }
        }
        else {
            isDone = YES;
        }
    };
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:libraryGroupsEnumeration
                         failureBlock:failureblock];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    library = nil;
    
    return [NSMutableArray arrayWithArray:pArr_videos];
}

+ (BOOL)export_assetUrl:(NSURL *)assetUrl
              to_folder:(NSString *)folderPath
                  error:(NSError **)error
{
    static const NSUInteger BufferSize = 1024 * 1024;
    __block BOOL isDone = NO;
    __block BOOL success = YES;
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *asset)
    {
        NSString *fileName = nil;
        
        ALAssetRepresentation* representation = [asset defaultRepresentation];
        fileName = [representation filename];
        
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
        
        NSFileManager *fmgr = [NSFileManager defaultManager];
        [fmgr createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        [fmgr removeItemAtPath:filePath error:nil];
        [fmgr createFileAtPath:filePath contents:nil attributes:nil];
        
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingToURL:fileUrl error:error];
        if (handle) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
            NSUInteger offset = 0, bytesRead = 0;
            
            do {
                @try {
                    bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:error];
                    [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
                    offset += bytesRead;
                }
                @catch (NSException *exception) {
                    if (error) {
                        *error = [NSError errorWithDomain:[exception reason] code:0 userInfo:nil];
                    }
                    success = NO;
                    break;
                }
            }
            while (bytesRead > 0);
            free(buffer);
        }
        else {
            success = NO;
        }
        
        isDone = YES;
    };
    
    ALAssetsLibraryAccessFailureBlock failureblock = ^(NSError *myerror)
    {
        success = NO;
        isDone = YES;
    };
    
    ALAssetsLibrary* assetslibrary = nil;
    
    if (assetUrl)
    {
        assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:assetUrl 
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    assetslibrary = nil;
    
    return success;
}

+ (BOOL)watermark_video_src:(NSURL *)src
                        des:(NSURL *)des
                  markLayer:(CALayer *)mark_layer
                 presetName:(NSString *)preset_name
             outputFileType:(NSString *)file_type
                      range:(O_item **)item_range
                      error:(NSError **)error
{
    AVAsset *asset_src = [AVAsset assetWithURL:src];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[des path]]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:[des path] error:error]) {
            return NO;
        }
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVAssetTrack *track_video_src = nil;
    AVMutableCompositionTrack *track_video_des = nil;
    
    CMTimeScale time_scale = [self video_fps:src];
    CMTime du = asset_src.duration;
    du = CMTimeMakeWithSeconds(CMTimeGetSeconds(du), time_scale);
    du = CMTimeMake(du.value - 1, time_scale);
    CMTimeRange range = CMTimeRangeMake(CMTimeMake(1, time_scale), du);
    
    if (item_range) {
        O_item *item = [O_item item];
        item.time_range = CMTimeRangeMake(kCMTimeZero, range.duration);
        
        *item_range = item;
    }
    
    for (AVAssetTrack *track_src in asset_src.tracks) {
        AVMutableCompositionTrack *track_des =
        [composition addMutableTrackWithMediaType:track_src.mediaType
                                 preferredTrackID:kCMPersistentTrackID_Invalid];
        
        
        
        BOOL success =
        [track_des insertTimeRange:range
                           ofTrack:track_src
                            atTime:kCMTimeZero
                             error:error];
        if (!success) {
            return NO;
        }
        
        if ([track_src.mediaType isEqualToString:AVMediaTypeVideo]) {
            track_video_src = track_src;
            track_video_des = track_des;
        }
    }
    
    if (!track_video_des) {
        *error = [NSError errorWithDomain:@"No video track found in video." code:-1 userInfo:nil];
        NSLog(@"No video track found in video.");
        return NO;
    }
    
    AVMutableVideoComposition *mark_composition = nil;
    if (mark_layer) {
        
        mark_composition =
        [AVMutableVideoComposition videoComposition];
        
        mark_composition.renderSize = track_video_src.naturalSize;
        mark_composition.frameDuration = CMTimeMake(1, time_scale);
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0.f, 0.f, track_video_src.naturalSize.width, track_video_src.naturalSize.height);
        videoLayer.frame = CGRectMake(0.f, 0.f, track_video_src.naturalSize.width, track_video_src.naturalSize.height);
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:mark_layer];
        
        mark_composition.animationTool =
        [AVVideoCompositionCoreAnimationTool
         videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
         inLayer:parentLayer];
        
        AVMutableVideoCompositionInstruction *mark_composition_instruction =
        [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        [mark_composition_instruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [composition duration])];
        
        AVMutableVideoCompositionLayerInstruction *mark_layer_instruction =
        [AVMutableVideoCompositionLayerInstruction
         videoCompositionLayerInstructionWithAssetTrack:track_video_src];
        
        [mark_layer_instruction setTransform:track_video_src.preferredTransform
                                      atTime:kCMTimeZero];
        
        mark_composition_instruction.layerInstructions = @[mark_layer_instruction];
        
        mark_composition.instructions = @[mark_composition_instruction];
    }
    
    AVAssetExportSession *exporter =
    [[AVAssetExportSession alloc] initWithAsset:composition
                                     presetName:preset_name];
    
    if (mark_layer) {
        [exporter setVideoComposition:mark_composition];
    }
    
    [exporter setOutputURL:des];
    exporter.outputFileType = file_type;
    
    __block BOOL isDone = NO;
    __block BOOL success = NO;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            success = YES;
        }
        
        NSError *err = [exporter error];
        
        if (err) {
            *error = err;
            NSLog(@"export error: %@", err);
        }
        
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }

    asset_src = nil;
    exporter = nil;

    return success;
}

+ (BOOL)watermark_video_src:(NSURL *)src
                        des:(NSURL *)des
                      marks:(NSArray *)marks
                 presetName:(NSString *)preset_name
             outputFileType:(NSString *)file_type
                      error:(NSError **)error
{
    NSString *tmp_folder = [NSTemporaryDirectory() stringByAppendingPathComponent:des.lastPathComponent];
    NSString *src_folder = [tmp_folder stringByAppendingPathComponent:@"src"];
    
    NSArray *src_array =
    [self split_video_src:src
                to_folder:src_folder
                   ranges:marks
               presetName:preset_name
           outputFileType:AVFileTypeQuickTimeMovie
            pathExtension:@"mov"
                    error:error];
    
    if (!src_array) {
        [[NSFileManager defaultManager] removeItemAtPath:tmp_folder error:nil];
        return NO;
    }
    
    if (src_array.count != marks.count) {
        [[NSFileManager defaultManager] removeItemAtPath:tmp_folder error:nil];
        return NO;
    }
    
    NSString *des_folder = [tmp_folder stringByAppendingPathComponent:@"des"];
    
    NSMutableArray *des_array = [NSMutableArray array];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:des_folder withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSMutableArray *array_range = [NSMutableArray array];
    for (int i = 0; i < marks.count; i++) {
        O_item *mark = marks[i];
        NSString *src_path = src_array[i];
        NSString *des_path = [des_folder stringByAppendingPathComponent:src_path.lastPathComponent];
        O_item *item_range = nil;
        
        BOOL sucess =
        [self watermark_video_src:[NSURL fileURLWithPath:src_path]
                              des:[NSURL fileURLWithPath:des_path]
                        markLayer:mark.layer_watermark
                       presetName:preset_name
                   outputFileType:file_type
                            range:&item_range
                            error:error];
        if (!sucess) {
            des_array = nil;
            [[NSFileManager defaultManager] removeItemAtPath:tmp_folder error:nil];
            return NO;
        }
        else {
            [array_range addObject:item_range];
            [des_array addObject:[NSURL fileURLWithPath:des_path]];
        }
    }
    
    NSLog(@"stitch videos");
    BOOL sucess =
    [self stitch_videos:des_array
                 ranges:array_range
                    des:des
             presetName:preset_name
         outputFileType:file_type
                  error:error];
    
    return sucess;
}

@end
