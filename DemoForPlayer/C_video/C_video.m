//
//  C_video.m
//  DemoForMultiStreamPlayer
//
//  Created by darklinden DarkLinden on 7/4/12.
//  Copyright (c) 2012 darklinden. All rights reserved.
//

#import "C_video.h"
#import "O_main_thread_host.h"

#if !__has_feature(objc_arc)
#error 请在ARC下编译此类。
#endif

@implementation O_watermark

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

+ (void)set_thumb_image:(NSURL*)url
                in_view:(UIImageView *)imgV
                   size:(CGSize)maxSize
{
    __block AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    __block AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *err){
        [O_main_thread_host do_on_main:^{
            if (result != AVAssetImageGeneratorSucceeded) {
                NSLog(@"setThumbImage failed with error %@", err);
            }
            else {
                [imgV setImage:[UIImage imageWithCGImage:im]];
            }
            asset = nil, generator = nil;
        }];
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
                                             error:nil]) {
                sourceAsset = nil;
                return NO;
            }
            compositionTrack.preferredTransform = track.preferredTransform;
        }
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
	
    exporter.outputURL = des;
    exporter.outputFileType = AVFileTypeAppleM4A;
	
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        sourceAsset = nil;
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    exporter = nil;
    
    return YES;
}

+ (BOOL)cut_video_src:(NSURL*)src
                  des:(NSURL*)des
                 from:(int64_t)start
                   to:(int64_t)end
                error:(NSError **)error
{
    __block BOOL isDone = NO;
    
    CMTime xstart;
    xstart.value = start;
    xstart.timescale = 1;
    xstart.flags = 1;
    xstart.epoch = 0;
    
    CMTime xduration;
    xduration.value = end - start;
    xduration.timescale = 1;
    xduration.flags = 1;
    xduration.epoch = 0;
    
    CMTimeRange duration = CMTimeRangeMake(xstart, xduration);
    
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
        if (![compositionTrack insertTimeRange:duration
                                       ofTrack:track
                                        atTime:kCMTimeZero
                                         error:nil]) {
            sourceAsset = nil;
            return NO;
        }
        compositionTrack.preferredTransform = track.preferredTransform;
    }
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
	
    exporter.outputURL = des;
	
    //NSLog(@"%@", [exporter supportedFileTypes]);
	//@"com.apple.quicktime-movie";
    
    exporter.outputFileType = @"com.apple.quicktime-movie";
	
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        sourceAsset = nil;
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    exporter = nil;
    
    return YES;
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
                       mark:(O_watermark *)mark
                      error:(NSError **)error
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[des path]])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:[des path] error:error]) {
            return NO;
        }
    }
    
    __block BOOL isDone = NO;
    __block BOOL success = YES;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    __block AVURLAsset * sourceAsset = [[AVURLAsset alloc] initWithURL:src options:nil];
    
    AVMutableCompositionTrack *video_track = nil;
    for (AVAssetTrack *track in [sourceAsset tracks]) {
        AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:track.mediaType preferredTrackID:kCMPersistentTrackID_Invalid];
        if (![compositionTrack insertTimeRange:track.timeRange
                                       ofTrack:track
                                        atTime:kCMTimeZero
                                         error:nil]) {
            sourceAsset = nil;
            return NO;
        }
        compositionTrack.preferredTransform = track.preferredTransform;
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            video_track = compositionTrack;
        }
    }
    
    //water mark
    AVMutableVideoComposition *video_composition = [AVMutableVideoComposition videoComposition];
    video_composition.renderSize = video_track.naturalSize;
    video_composition.frameDuration = mark.range.duration;
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0.f, 0.f, video_track.naturalSize.width, video_track.naturalSize.width);
    videoLayer.frame = CGRectMake(0.f, 0.f, video_track.naturalSize.width, video_track.naturalSize.width);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:mark.layer_watermark];
    
    video_composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction *video_composition_instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    [video_composition_instruction setTimeRange:mark.range];
    
    AVMutableVideoCompositionLayerInstruction *layer_instruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:video_track];
    [layer_instruction setTransform:video_track.preferredTransform atTime:mark.range.start];
    
    video_composition_instruction.layerInstructions = @[layer_instruction];
    
    video_composition.instructions = @[video_composition_instruction];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480];
    [exporter setVideoComposition:video_composition];
    [exporter setOutputURL:des];
    exporter.outputFileType = @"com.apple.quicktime-movie";
    //     [avAssetExportSession setOutputFileType:AVFileTypeQuickTimeMovie];//这句话要是要的话，会出错的。。。
    [exporter setShouldOptimizeForNetworkUse:YES];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        sourceAsset = nil;
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            success = YES;
        }
        else {
            *error = [exporter error];
            success = NO;
        }
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    exporter = nil;
    
    return success;
}

@end
