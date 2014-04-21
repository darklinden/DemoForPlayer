//
//  VC_player.m
//  DemoForPlayer
//
//  Created by user_admin on A/15/2014.
//  Copyright (c) 2014 darklinden. All rights reserved.
//

#import "VC_player.h"
#import "V_player.h"

@interface VC_player ()
@property (nonatomic,   weak) IBOutlet V_player *pV_player;
@end

@implementation VC_player

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *bi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pBtn_cancel_clicked:)];
    self.navigationItem.leftBarButtonItem = bi;
}

- (void)pBtn_cancel_clicked:(id)sender
{
    [self.pV_player removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

+ (void)play:(NSURL *)url
{
    UIViewController *root = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    VC_player *pVC_player = [[VC_player alloc] initWithNibName:@"VC_player" bundle:nil];
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:pVC_player];
    pVC_player.view.frame = root.view.frame;
    nv.view.frame = root.view.frame;
    
    [root presentViewController:nv animated:YES completion:^{
        [pVC_player play:url];
    }];
}

- (void)play:(NSURL *)url
{
    [self.pV_player play:url];
}

@end
