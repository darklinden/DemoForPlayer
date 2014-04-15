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
    
    [vision setCaptureSessionPreset:AVCaptureSessionPreset640x480];
    [vision setCameraMode:PBJCameraModeVideo];
    [vision setCameraOrientation:PBJCameraOrientationPortrait];
    [vision setFocusMode:PBJFocusModeContinuousAutoFocus];
    [vision setOutputFormat:PBJOutputFormatSquare];
    [vision setVideoRenderingEnabled:YES];
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
    
//    [C_video loadVideoByPath:videoPath andSavePath:des];
    CMTimeRange range = [C_video video_range:[NSURL fileURLWithPath:src]];
    
    O_watermark *mark = [O_watermark watermark];
    mark.range = range;
    
    //    CATextLayer *t_layer = [[CATextLayer alloc] init];
    //    t_layer.string = @"Hello World";
    //    t_layer.font = (__bridge CFTypeRef)(@"Helvetica");
    //    t_layer.fontSize = 20.0f;
    //    t_layer.shadowOpacity = 0.6f ;
    //    t_layer.backgroundColor = [UIColor clearColor].CGColor;
    //    t_layer.foregroundColor = [UIColor redColor].CGColor;
    
    UIImage *img = [UIImage imageNamed:@"logo.png"];
    CALayer *img_layer = [CALayer layer];
    img_layer.frame = CGRectMake(0, 60, 320, 222);
    img_layer.contents = (id)img.CGImage;
    
    mark.layer_watermark = img_layer;
    
    NSError *err = nil;
//    [C_video watermark_video_src:[NSURL fileURLWithPath:src]
//                             des:[NSURL fileURLWithPath:des]
//                            mark:mark
//                           error:&err];
    NSLog(@"%@", err);
    [C_video loadVideoByPath:src andSavePath:des];
}

@end
