//
//  ViewController.m
//  acceleration
//
//  Created by chen on 2017/7/19.
//  Copyright © 2017年 chen. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "libu3d.h"

#define FPS 1/60.f
#define GRAVITY(accelete) accelete * 9.8f
#define RATIO 20.0f //屏幕和现实比例系数

typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} ReduceAcce;

@interface ViewController ()

@property (strong, nonatomic) CMMotionManager *manager;
@property (strong, nonatomic) NSString *log;
@property (assign, nonatomic) BOOL isOpenLog;
@property (assign, nonatomic) BOOL isGyro;
//@property (weak, nonatomic) IBOutlet UIButton *openLogButton;
//@property (weak, nonatomic) IBOutlet UIButton *motionButton;
@property (assign, nonatomic) CGFloat previousVx;//上一帧末速度x方向
@property (assign, nonatomic) CGFloat previousVy;//上一帧末速度y方向
@property (assign, nonatomic) CGFloat previousVz;
@property (assign, nonatomic) CGFloat tempTime;

@end

@implementation ViewController{
    UIView *_view;
}

- (void)initialize {
    _log = @"";
    _previousVx = 0.f;
    _previousVy = 0.f;
    _previousVz = 0.f;
    _tempTime = 0.f;
    
    _view = [[UIView alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2 - 30, self.view.frame.size.height/2 - 30, 60, 60)];
    _view.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:_view];
    
    _manager = [[CMMotionManager alloc] init];
    _manager.gyroUpdateInterval = 0.1f;
    _manager.accelerometerUpdateInterval = FPS;
    
    _logTextView.layoutManager.allowsNonContiguousLayout = NO;
    
    libu3d *u3d = [[libu3d alloc]initWithTarget:self];
    [self.view addSubview:u3d];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
    
    [self startGyro];
    [self startAcceleration];
    [self startDeviceMotion];
//    [self startMagnetometer];
}

- (void)startGyro {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [_manager startGyroUpdatesToQueue:queue withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        if (!_isGyro) {
            return;
        }
        CMRotationRate rotation = gyroData.rotationRate;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _gyroX.text = [NSString stringWithFormat:@"%.4f", rotation.x];
            _gyroY.text = [NSString stringWithFormat:@"%.4f", rotation.y];
            _gyroZ.text = [NSString stringWithFormat:@"%.4f", rotation.z];
            if (_isOpenLog) {
                self.log = [NSString stringWithFormat:@"GYRO, x:%@ y:%@ z:%@, \n%.4f", _gyroX.text, _gyroY.text, _gyroZ.text, gyroData.timestamp];
            }
        });
    }];
}

- (void)startAcceleration {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [_manager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        if (_isGyro) {
            return;
        }
        CMAcceleration acceleration = accelerometerData.acceleration;
        NSString *xString = [NSString stringWithFormat:@"%.4f", acceleration.x];
        NSString *yString = [NSString stringWithFormat:@"%.4f", acceleration.y];
        NSString *zString = [NSString stringWithFormat:@"%.4f", acceleration.z];
        
        if (_isOpenLog) {
            self.log = [NSString stringWithFormat:@"ACCE, x:%@ y:%@ z:%@, \n%f", _accelerateX.text, _accelerateY.text, _accelerateZ.text, accelerometerData.timestamp];
        }
        
        //速度位移计算
        ReduceAcce acce = [self reduceGravityAcceWithData:acceleration];
        CGFloat deltaSx = _previousVx * FPS + 0.5 * GRAVITY(acce.x) * sqrt(FPS);//x方向∆S
        CGFloat deltaSy = _previousVy * FPS + 0.5 * GRAVITY(acce.y) * sqrt(FPS);//y方向∆S
        CGFloat deltaSz = _previousVz * FPS + 0.5 * 32.5/1 * acceleration.z * sqrt(FPS);
        
        CGFloat x = _view.frame.origin.x + deltaSx * RATIO;
        CGFloat y = _view.frame.origin.y - deltaSy * RATIO;
        CGRect rect = CGRectMake(x, y, CGRectGetWidth(_view.frame), CGRectGetHeight(_view.frame));
//        CGRect rect = CGRectMake(CGRectGetWidth(self.view.frame)/2 - CGRectGetWidth(_view.frame)/2, CGRectGetHeight(self.view.frame)/2 - CGRectGetHeight(_view.frame)/2, CGRectGetWidth(_view.frame), CGRectGetHeight(_view.frame));
        //上一帧末速度
        _previousVx = _previousVx + GRAVITY(acce.x) * FPS;
        _previousVy = _previousVy + GRAVITY(acce.y) * FPS;
        _previousVz = _previousVz + 32.5/1 * acceleration.z * FPS;
        CGFloat scale =  1 + deltaSz/_view.frame.size.width;
        
        _tempTime += FPS;
        if (_tempTime > 0.1f) {
//            NSLog(@"Vx: %.3f, Vy: %.3f", _previousVx, _previousVy);
            NSLog(@"%f，%f, %f", deltaSx, acce.x, acceleration.x);
            _tempTime = 0.0f;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _accelerateX.text = xString;
            _accelerateY.text = yString;
            _accelerateZ.text = zString;
            _logTextView.text = _log;
            _view.frame = rect;
//            _view.transform = CGAffineTransformScale(_view.transform, scale, scale);
        });
        
        
    }];
}

- (void)startMagnetometer {
    [_manager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error) {
        
    }];
}

- (void)startDeviceMotion {
    _manager.deviceMotionUpdateInterval = 1/30.f;
    [_manager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        CMAttitude *attitude = motion.attitude;
//        NSLog(@"%@", [NSString stringWithFormat:@"%f, %f, %f, %f", attitude.quaternion.x, attitude.quaternion.y, attitude.quaternion.z, attitude.quaternion.w]);
//        NSLog(@"%@", [NSString stringWithFormat:@"%f, %f, %f", attitude.roll, attitude.pitch, attitude.yaw]);
    }];
    [_manager startDeviceMotionUpdates];
    
}

- (void)setLog:(NSString *)log {
    _log = [NSString stringWithFormat:@"%@%@\n", _log, log];
    if (_log.length > 3000) {
        _log = [_log substringWithRange:NSMakeRange(_log.length - 3000, 3000)];
    }
//    [_logTextView scrollRangeToVisible:NSMakeRange(_logTextView.text.length, 1)];
}

- (IBAction)openLog:(UIButton *)sender {
    if (!_isOpenLog) {
        _isOpenLog = YES;
        [sender setTitle:@"stop" forState:UIControlStateNormal];
    } else {
        _isOpenLog = NO;
        [sender setTitle:@"start" forState:UIControlStateNormal];
    }
}

- (IBAction)clearLog:(UIButton *)sender {
    _logTextView.text = nil;
    _log = @"";
}

- (IBAction)changeMotion:(UIButton *)sender {
    if (!_isGyro) {
        _isGyro = YES;
        [sender setTitle:@"Gyro" forState:UIControlStateNormal];
    } else {
        _isGyro = NO;
        [sender setTitle:@"Acce" forState:UIControlStateNormal];
    }
}

- (IBAction)resetViewFrame:(UIButton *)sender {
    _view.frame = CGRectMake(CGRectGetWidth(self.view.frame)/2 - 30, CGRectGetHeight(self.view.frame)/2 - 30, 60, 60);
    _previousVx = 0.f;
    _previousVy = 0.f;
    _previousVz = 0.f;
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"alert" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"asdf");
    }];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:@"..." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (ReduceAcce)reduceGravityAcceWithData:(CMAcceleration)acceleration {
    CMAttitude *attitude = _manager.deviceMotion.attitude;
    dispatch_async(dispatch_get_main_queue(), ^{
        _gyroX.text = [NSString stringWithFormat:@"%.4f", attitude.roll * 180/M_PI];
        _gyroY.text = [NSString stringWithFormat:@"%.4f", attitude.pitch * 180/M_PI];
        _gyroZ.text = [NSString stringWithFormat:@"%.4f", attitude.yaw * 180/M_PI];
    });
    
    CGFloat x = (acceleration.x - sin(attitude.roll));
    CGFloat y = (acceleration.y + sin(attitude.pitch));
    CGFloat z = (acceleration.z - sin(attitude.yaw));
    
    ReduceAcce acce = {x, y, z};
    
    return acce;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
