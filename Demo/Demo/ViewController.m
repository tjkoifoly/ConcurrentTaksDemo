//
//  ViewController.m
//  Demo
//
//  Created by NGUYEN CHI CONG on 3/31/15.
//  Copyright (c) 2015 if. All rights reserved.
//

#import "ViewController.h"
#import "TasksManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btStop;
@property (weak, nonatomic) IBOutlet UIButton *btStart;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self refreshUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/**-----------------------------------------------------------------**/
#pragma mark - Actions

- (IBAction)startButtonTapped:(id)sender {
    [[TasksManager sharedManager] startTasks];
    [self refreshUI];
}
- (IBAction)stopButtonTapped:(id)sender {
    [[TasksManager sharedManager] stopTasks];
    [self refreshUI];
}

- (void)refreshUI{
    if ([[TasksManager sharedManager] isRunning]){
        self.btStart.enabled = NO;
        self.btStop.enabled = YES;
    }else{
        self.btStop.enabled = NO;
        self.btStart.enabled = YES;
    }
}

@end
