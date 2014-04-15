//
//  C_video.m
//  DemoForMultiStreamPlayer
//
//  Created by darklinden DarkLinden on 7/4/12.
//  Copyright (c) 2012 darklinden. All rights reserved.
//

#import "C_video.h"

#if !__has_feature(objc_arc)
#error 请在ARC下编译此类。
#endif

@implementation O_watermark

+ (id)watermark
{
    O_watermark *mark = [[O_watermark alloc] init];
    return mark;
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
                                         error:error]) {
            sourceAsset = nil;
            return NO;
        }
        compositionTrack.preferredTransform = track.preferredTransform;
        NSLog(@"%@", track.mediaType);
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            video_track = compositionTrack;
        }
    }
    
    NSLog(@"naturalSize %@", NSStringFromCGSize(video_track.naturalSize));
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
    
    video_composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                       videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                       inLayer:parentLayer];
    
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
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            success = YES;
        }
        else {
            NSError *err = [exporter error];
            dispatch_async(dispatch_get_main_queue(), ^{
                *error = [NSError errorWithDomain:err.domain code:err.code userInfo:err.userInfo];
            });
            success = NO;
        }
        
        switch (exporter.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"AVAssetExportSessionStatusCompleted");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"AVAssetExportSessionStatusFailed");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            default:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
        }
        
        isDone = YES;
    }];
    
    while (!isDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
    }
    
    sourceAsset = nil;
    exporter = nil;
    
    return success;
}

+ (void) loadVideoByPath:(NSString*) v_strVideoPath andSavePath:(NSString*) v_strSavePath {
    
    NSLog(@"\nv_strVideoPath = %@ \nv_strSavePath = %@\n ",v_strVideoPath,v_strSavePath);
    AVAsset *avAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:v_strVideoPath]];
    CMTime assetTime = [avAsset duration];
    Float64 duration = CMTimeGetSeconds(assetTime);
    NSLog(@"视频时长 %f\n",duration);
    
    AVMutableComposition *avMutableComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *avMutableCompositionTrack = [avMutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *avAssetTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    NSError *error = nil;
    // 这块是裁剪,rangtime .前面的是开始时间,后面是裁剪多长
    [avMutableCompositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0.1f, 30), CMTimeMakeWithSeconds(duration, 30))
                                       ofTrack:avAssetTrack
                                        atTime:kCMTimeZero
                                         error:&error];
    
    AVMutableVideoComposition *avMutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    avMutableVideoComposition.renderSize = CGSizeMake(320.0f, 480.0f);
    avMutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    //     CALayer *animatedTitleLayer = [self buildAnimatedTitleLayerForSize:CGSizeMake(320, 88)];
    
    UIImage *waterMarkImage = [UIImage imageNamed:@"logo.png"];
    CALayer *waterMarkLayer = [CALayer layer];
    waterMarkLayer.frame = CGRectMake(0, 60, 320, 222);
    waterMarkLayer.contents = (id)waterMarkImage.CGImage;
    
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, 320, 480);
    videoLayer.frame = CGRectMake(0, 0, 320, 480);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:waterMarkLayer];
    
    avMutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction *avMutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    [avMutableVideoCompositionInstruction setTimeRange:CMTimeRangeMake(kCMTimeZero, [avMutableComposition duration])];
    
    AVMutableVideoCompositionLayerInstruction *avMutableVideoCompositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:avAssetTrack];
    [avMutableVideoCompositionLayerInstruction setTransform:avAssetTrack.preferredTransform atTime:kCMTimeZero];
    
    avMutableVideoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:avMutableVideoCompositionLayerInstruction];
    
    
    avMutableVideoComposition.instructions = [NSArray arrayWithObject:avMutableVideoCompositionInstruction];
    
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    if ([fm fileExistsAtPath:v_strSavePath]) {
        NSLog(@"video is have. then delete that");
        if ([fm removeItemAtPath:v_strSavePath error:&error]) {
            NSLog(@"delete is ok");
        }else {
            NSLog(@"delete is no error = %@",error.description);
        }
    }
    
    
    AVAssetExportSession *avAssetExportSession = [[AVAssetExportSession alloc] initWithAsset:avMutableComposition presetName:AVAssetExportPreset640x480];
    [avAssetExportSession setVideoComposition:avMutableVideoComposition];
    [avAssetExportSession setOutputURL:[NSURL fileURLWithPath:v_strSavePath]];
    avAssetExportSession.outputFileType = @"com.apple.quicktime-movie";
    //     [avAssetExportSession setOutputFileType:AVFileTypeQuickTimeMovie];//这句话要是要的话，会出错的。。。
    [avAssetExportSession setShouldOptimizeForNetworkUse:YES];
    [avAssetExportSession exportAsynchronouslyWithCompletionHandler:^(void){
        switch (avAssetExportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporting failed %@",[avAssetExportSession error]);
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporting completed");
                //下面是按照上面的要求合成视频的过程。
                // 下面是把视频存到本地相册里面，存储完后弹出对话框。
                //                NSLog(@"该视频的大小为：%lf M",[self fileSizeAtPath:v_strSavePath]);
                //                [_assetLibrary writeVideoAtPathToSavedPhotosAlbum:avAssetExportSession.outputURL completionBlock:^(NSURL *assetURL, NSError *error1) {
                //                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"好的!" message: @"整合并保存成功！"
                //                                                                   delegate:nil
                //                                                          cancelButtonTitle:@"OK"
                //                                                          otherButtonTitles:nil];
                //                    [alert show];
                //
                //                }];
                break;
            case AVAssetExportSessionStatusCancelled:
                
                
                NSLog(@"export cancelled");
                
                break;
        }
    }];
    if (avAssetExportSession.status != AVAssetExportSessionStatusCompleted){
        NSLog(@"Retry export");
    }
}

@end
