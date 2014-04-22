//
//  VC_root.m
//  DemoForPlayer
//
//  Created by user_admin on A/15/2014.
//  Copyright (c) 2014 darklinden. All rights reserved.
//

#import "VC_root.h"
#import "PBJFocusView.h"
#import "PBJVision.h"
#import "PBJVisionUtilities.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <GLKit/GLKit.h>
#import "C_video.h"
#import "VC_player.h"

@interface VC_root () <PBJVisionDelegate, UIGestureRecognizerDelegate>
@property (nonatomic,   weak) IBOutlet UIView *previewView;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) PBJFocusView *focusView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation VC_root

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _resetCapture];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self video_init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self _resetCapture];
    [[PBJVision sharedInstance] startPreview];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[PBJVision sharedInstance] stopPreview];
}

- (void)video_init
{
    // preview and AV layer
    _previewView.backgroundColor = [UIColor blackColor];
    _previewLayer = [[PBJVision sharedInstance] previewLayer];
    _previewLayer.frame = _previewView.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewView.layer addSublayer:_previewLayer];
    [[PBJVision sharedInstance] setPresentationFrame:_previewView.frame];
    
    // focus view
    _focusView = [[PBJFocusView alloc] initWithFrame:CGRectZero];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleFocusTapGesterRecognizer:)];
    _tapGestureRecognizer.delegate = self;
    _tapGestureRecognizer.numberOfTapsRequired = 1;
//    _tapGestureRecognizer.enabled = NO;
    [_previewView addGestureRecognizer:_tapGestureRecognizer];
}

- (void)_resetCapture
{
    PBJVision *vision = [PBJVision sharedInstance];
    vision.delegate = self;
    
    if ([vision isCameraDeviceAvailable:PBJCameraDeviceBack]) {
        [vision setCameraDevice:PBJCameraDeviceBack];
    } else {
        [vision setCameraDevice:PBJCameraDeviceFront];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [vision setCaptureSessionPreset:AVCaptureSessionPreset640x480];
        [vision setCameraMode:PBJCameraModeVideo];
        [vision setCameraOrientation:PBJCameraOrientationPortrait];
        [vision setFocusMode:PBJFocusModeContinuousAutoFocus];
        [vision setOutputFormat:PBJOutputFormatSquare];
        [vision setVideoRenderingEnabled:YES];
    }
    else {
        [vision setCaptureSessionPreset:AVCaptureSessionPreset1920x1080];
        [vision setCameraMode:PBJCameraModeVideo];
        
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
                [vision setCameraOrientation:PBJCameraOrientationPortrait];
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                [vision setCameraOrientation:PBJCameraOrientationPortraitUpsideDown];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [vision setCameraOrientation:PBJCameraOrientationLandscapeRight];
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [vision setCameraOrientation:PBJCameraOrientationLandscapeLeft];
                break;
            default:
                [vision setCameraOrientation:PBJCameraOrientationPortrait];
                break;
        }
        
        [vision setFocusMode:PBJFocusModeContinuousAutoFocus];
        [vision setOutputFormat:PBJOutputFormatPreset];
        [vision setVideoRenderingEnabled:YES];
    }
}

#pragma mark - ibaction
- (IBAction)pBtn_start_record_clicked:(id)sender {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [[PBJVision sharedInstance] startVideoCapture];
}

- (IBAction)pBtn_pause_record_clicked:(id)sender {
    [[PBJVision sharedInstance] pauseVideoCapture];
}

- (IBAction)pBtn_resume_record_clicked:(id)sender {
    [[PBJVision sharedInstance] resumeVideoCapture];
}

- (IBAction)pBtn_switch_camera_clicked:(id)sender {
    PBJVision *vision = [PBJVision sharedInstance];
    if (vision.cameraDevice == PBJCameraDeviceBack) {
        [vision setCameraDevice:PBJCameraDeviceFront];
    } else {
        [vision setCameraDevice:PBJCameraDeviceBack];
    }
}

- (IBAction)pBtn_save_clicked:(id)sender {
    NSLog(@"%s", __FUNCTION__);
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[PBJVision sharedInstance] endVideoCapture];
}

- (IBAction)pBtn_play_save_clicked:(id)sender {
    NSString *des = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"des.mov"];
    [VC_player play:[NSURL fileURLWithPath:des]];
}

- (void)_handleFocusTapGesterRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:_previewView];
    
    // auto focus is occuring, display focus view
    CGPoint point = tapPoint;
    
    CGRect focusFrame = _focusView.frame;
#if defined(__LP64__) && __LP64__
    focusFrame.origin.x = rint(point.x - (focusFrame.size.width * 0.5));
    focusFrame.origin.y = rint(point.y - (focusFrame.size.height * 0.5));
#else
    focusFrame.origin.x = rintf(point.x - (focusFrame.size.width * 0.5f));
    focusFrame.origin.y = rintf(point.y - (focusFrame.size.height * 0.5f));
#endif
    [_focusView setFrame:focusFrame];
    
    [_previewView addSubview:_focusView];
    [_focusView startAnimation];
    
    CGPoint adjustPoint = [PBJVisionUtilities convertToPointOfInterestFromViewCoordinates:tapPoint inFrame:_previewView.frame];
    [[PBJVision sharedInstance] focusExposeAndAdjustWhiteBalanceAtAdjustedPoint:adjustPoint];
}

#pragma mark - session
- (void)visionSessionWillStart:(PBJVision *)vision
{
}

- (void)visionSessionDidStart:(PBJVision *)vision
{
}

- (void)visionSessionDidStop:(PBJVision *)vision
{
}

#pragma mark - 焦点和曝光
- (void)visionWillStartFocus:(PBJVision *)vision
{
}

- (void)visionDidStopFocus:(PBJVision *)vision
{
    if (_focusView && [_focusView superview]) {
        [_focusView stopAnimation];
    }
}

- (void)visionWillChangeExposure:(PBJVision *)vision
{
}

- (void)visionDidChangeExposure:(PBJVision *)vision
{
    if (_focusView && [_focusView superview]) {
        [_focusView stopAnimation];
    }
}

#pragma mark - 录制事件

- (void)visionDidStartVideoCapture:(PBJVision *)vision
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)visionDidPauseVideoCapture:(PBJVision *)vision
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"senconds %lf", vision.capturedVideoSeconds);
}

- (void)visionDidResumeVideoCapture:(PBJVision *)vision
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)vision:(PBJVision *)vision capturedVideo:(NSDictionary *)videoDict error:(NSError *)error
{
    if (error
        && [error.domain isEqual:PBJVisionErrorDomain]
        && error.code == PBJVisionErrorCancelled) {
        NSLog(@"recording session cancelled");
        return;
    } else if (error) {
        NSLog(@"encounted an error in video capture (%@)", error);
        return;
    }
    
    NSString *src = [videoDict objectForKey:PBJVisionVideoPathKey];
    NSString *des = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"des.mov"];
    
//    /*
     //拆分视频并逐个创建字幕
    NSLog(@"second length：%llu", [C_video video_length:[NSURL fileURLWithPath:src]]);
    CMTimeScale timescale = [C_video video_fps:[NSURL fileURLWithPath:src]];
    CMTimeRange range = [C_video video_range:[NSURL fileURLWithPath:src]];
    NSMutableArray *array = [NSMutableArray array];
    
    CMTime position = kCMTimeZero;
    CMTime duration = CMTimeMake(timescale, timescale);
    
    int cnt = CMTimeGetSeconds(range.duration);
    
    for (int i = 0; i < cnt; i++) {
        O_item *mark = [O_item item];
        CMTime tmp_duration = CMTimeMake(timescale + 3, timescale);
        mark.time_range = CMTimeRangeMake(position, tmp_duration);
        [array addObject:mark];
        
        CATextLayer *t_layer = [[CATextLayer alloc] init];
        t_layer.string = [NSString stringWithFormat:@"%d", i];
        t_layer.font = (__bridge CFTypeRef)(@"Helvetica");
        t_layer.fontSize = 100.0f;
        t_layer.shadowOpacity = 0.6f ;
        t_layer.backgroundColor = [UIColor clearColor].CGColor;
        t_layer.foregroundColor = [UIColor redColor].CGColor;
        t_layer.frame = CGRectMake(0.f, 0.f, 200.f, 200.f);
        mark.layer_watermark = t_layer;
        
        position = CMTimeMake(position.value + duration.value - 1, timescale);
    }
    
    O_item *mark = [O_item item];
    mark.time_range = CMTimeRangeMake(position,
                                     CMTimeMake(CMTimeGetSeconds(range.duration) * timescale, timescale));
    [array addObject:mark];
    
    NSDate *old = [NSDate date];
    BOOL success = NO;
    NSError *err = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        success = [C_video watermark_video_src:[NSURL fileURLWithPath:src]
                                 des:[NSURL fileURLWithPath:des]
                               marks:array
                          presetName:AVAssetExportPreset640x480
                      outputFileType:AVFileTypeQuickTimeMovie
                               error:&err];
    }
    else {
       success = [C_video watermark_video_src:[NSURL fileURLWithPath:src]
                                 des:[NSURL fileURLWithPath:des]
                               marks:array
                          presetName:AVAssetExportPreset1920x1080
                      outputFileType:AVFileTypeQuickTimeMovie
                               error:&err];
    }
    
    NSLog(@"success: %d error: %@", success, err);
    
    float fsecond = - old.timeIntervalSinceNow;
    NSString *msg = [NSString stringWithFormat:@"success: %d error: %@ time cost %fs, tap <play save> to play.", success, err, fsecond];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Over" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
//    */
    
    //创建动态字幕
//    CALayer *content_layer = [[CALayer alloc] init];
//    
//    CATextLayer *t_layer = [[CATextLayer alloc] init];
//    t_layer.string = [NSString stringWithFormat:@"%d", 0];
//    t_layer.font = (__bridge CFTypeRef)(@"Helvetica");
//    t_layer.fontSize = 20.0f;
//    t_layer.shadowOpacity = 0.6f ;
//    t_layer.backgroundColor = [UIColor clearColor].CGColor;
//    t_layer.foregroundColor = [UIColor redColor].CGColor;
//    t_layer.frame = CGRectMake(0.f, 0.f, 100.f, 100.f);
//    [content_layer addSublayer:t_layer];
//    
//    
//    CATextLayer *last_layer = t_layer;
//    NSMutableArray *textanimarray = [NSMutableArray array];
//    CGFloat totalDuration = 0.f;
//    
//    for (int i = 0; i < 2; i++) {
//        CABasicAnimation *textanim = [CABasicAnimation animationWithKeyPath:@"sublayers"];
//        textanim.duration = 1.f;
//        textanim.fromValue = @[last_layer];
//        
//        CATextLayer *next_layer = [[CATextLayer alloc] init];
//        next_layer.string = [NSString stringWithFormat:@"%d", i];
//        next_layer.font = (__bridge CFTypeRef)(@"Helvetica");
//        next_layer.fontSize = 20.0f;
//        next_layer.shadowOpacity = 0.6f ;
//        next_layer.backgroundColor = [UIColor clearColor].CGColor;
//        next_layer.foregroundColor = [UIColor redColor].CGColor;
//        next_layer.frame = CGRectMake(0.f, 0.f, 100.f, 100.f);
//        
//        textanim.toValue = @[next_layer];
//        
//        last_layer = next_layer;
//        
//        textanim.beginTime = i + 1;
//        textanim.removedOnCompletion = NO;
//        textanim.fillMode = kCAFillModeBoth;
//        textanim.cumulative = YES;
//        [textanimarray addObject:textanim];
//        
//        totalDuration += 1.f;
//    }
//    
//    CAAnimationGroup* textgroup = [CAAnimationGroup animation];
//    [textgroup setDuration:totalDuration];
//    [textgroup setAnimations:textanimarray];
//    [content_layer addAnimation:textgroup forKey:nil];// @"contentAnimate"];
//    [self.view.layer addSublayer:content_layer];
    //draw image
    
//    UIImage *image1 = [UIImage imageNamed:@"logo.png"];
//    UIImage *image2 = [UIImage imageNamed:@"1.gif"];
//    CALayer *img_layer = [CALayer layer];
//    img_layer.frame = CGRectMake(0, 0, 100, 100);
//    img_layer.contents = (id)image1.CGImage;
//    CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
//    crossFade.duration = 5.0;
//    crossFade.fromValue = (__bridge id)(image1.CGImage);
//    crossFade.toValue = (__bridge id)(image2.CGImage);
//    [img_layer addAnimation:crossFade forKey:@"animateContents"];
//    [self.view.layer addSublayer:img_layer];
//    NSError *err = nil;
//    [C_video watermark_video_src:[NSURL fileURLWithPath:src]
//                             des:[NSURL fileURLWithPath:des]
//                       markLayer:img_layer
//                      presetName:AVAssetExportPreset640x480
//                  outputFileType:AVFileTypeQuickTimeMovie
//                           error:&err];
//    NSLog(@"%@", err);
}

@end
