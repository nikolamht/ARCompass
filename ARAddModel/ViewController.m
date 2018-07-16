//
//  ViewController.m
//  ARAddModel
//
//  Created by miaoht on 2018/6/12.
//  Copyright © 2018年 miaoht. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import "PlaneNode.h"
#import <CoreLocation/CoreLocation.h>
#import <math.h>

@interface ViewController ()<ARSCNViewDelegate,CLLocationManagerDelegate>
//AR视图
@property(nonatomic , strong) ARSCNView *scnView;
//会话配置
@property(nonatomic , strong) ARConfiguration *sessionConfig;
//遮罩视图
@property(nonatomic , strong) UIView *maskView;
//提示标签
@property(nonatomic , strong) UILabel *tipLabel;
//定位管理者
@property(nonatomic , strong) CLLocationManager *locationManager;
//指南针图片
@property(nonatomic , strong) UIImageView *compasspointer;
//地面
@property(nonatomic , strong) SCNNode *floor;
//方向是否已经对齐
@property(nonatomic , assign) BOOL aligned;
//路线nodes
@property(nonatomic , strong) NSMutableArray *routeNodes;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scnView];
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.tipLabel];
    self.scnView.delegate = self;
    //显示fps信息
    self.scnView.showsStatistics = YES;
    //显示检测到的特征点
    self.scnView.debugOptions = ARSCNDebugOptionShowWorldOrigin;
    [self.scnView.scene.rootNode addChildNode:self.floor];
    
    [self.view addSubview:self.compasspointer];
    
    //管理者的代理
    self.locationManager.delegate = self;
    // 开始获取用户位置 注意:获取用户的方向信息是不需要用户授权的
    [self.locationManager startUpdatingHeading];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self.scnView.session runWithConfiguration:self.sessionConfig];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scnView.session pause];
}

- (void)updateRoute {
    //    CGPoint point = [tap locationInView:self.scnView];
    //    //命中测试，类型为已经存在的平面
    //    NSArray<ARHitTestResult *> *results = [self.scnView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    //    if (results.count > 0) {
    //        ARHitTestResult *result = [results firstObject];
    //        SCNVector3 vector3 = SCNVector3Make(result.worldTransform.columns[3].x, result.worldTransform.columns[3].y, result.worldTransform.columns[3].z);
    //        //获取模型场景
    //        SCNScene *scene = [SCNScene sceneNamed:@"Cylinder.scn"];
    //        SCNNode *node = [scene.rootNode clone];
    //        node.position = vector3;
    //        node.eulerAngles = SCNVector3Make(0, M_PI, 0);
    //        [self.scnView.scene.rootNode addChildNode:node];
    //    }
    
    NSLog(@"%@",self.routes);
    
    NSArray *lpoint = nil;
    
    for (NSInteger i = 0; i < self.routes.count; i++) {
        
        NSArray *arry = self.routes[i];
        
        double v_x = [arry[0] doubleValue];
        double v_y = [arry[1] doubleValue];
        if (lpoint) {
            v_x = [arry[0] doubleValue]-[lpoint[0] doubleValue];
            v_y = [arry[1] doubleValue]-[lpoint[1] doubleValue];
        }
        double angle = 0.0;
        
        double m = sqrt(pow(v_x, 2)+pow(v_y, 2));
        if (m != 0) {
            angle = v_x<0?-acos(v_y/m):acos(v_y/m);
        }
        
        double x_2 = 0.0;
        double y_2 = 0.0;
        if (lpoint) {
            x_2 = ([arry[0] doubleValue]+[lpoint[0] doubleValue])/2.0;
            y_2 = ([arry[1] doubleValue]+[lpoint[1] doubleValue])/2.0;
        }else {
            x_2 = ([arry[0] doubleValue])/2.0;
            y_2 = ([arry[1] doubleValue])/2.0;
        }
        
        SCNVector3 vector3 = SCNVector3Make(self.floor.worldTransform.m41+x_2, self.floor.worldTransform.m42+0.01, self.floor.worldTransform.m43+y_2);
        SCNNode *node = self.routeNodes[i];
        node.position = vector3;
        node.transform = SCNMatrix4Translate(node.transform, 0, 1.5, 0);
        //计算欧拉角
        node.eulerAngles = SCNVector3Make(0, angle, 0);
        lpoint = arry;
    }
}

#pragma mark - session代理
- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    switch (camera.trackingState) {
        case ARTrackingStateNotAvailable:
        {
            self.tipLabel.text = @"跟踪不可用";
            self.aligned = NO;
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.7;
            }];
        } break;
        case ARTrackingStateLimited:
        {
            self.aligned = NO;
            NSString *title = @"有限的跟踪,原因:";
            NSString *desc;
            switch (camera.trackingStateReason) {
                case ARTrackingStateReasonNone:
                {
                    desc = @"不受约束";
                } break;
                case ARTrackingStateReasonInitializing:
                {
                    desc = @"正在初始化";
                } break;
                case ARTrackingStateReasonExcessiveMotion:
                {
                    desc = @"设备移动过快";
                } break;
                case ARTrackingStateReasonInsufficientFeatures:
                {
                    desc = @"提取不到足够特征点";
                } break;
                default:
                    break;
            }
            self.tipLabel.text = [NSString stringWithFormat:@"%@%@",title,desc];
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = .6;
            }];
        } break;
        case ARTrackingStateNormal:
        {
            self.tipLabel.text = @"跟踪正常";
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.0;
            }];
        } break;
        default:
            break;
    }
}

- (void)sessionWasInterrupted:(ARSession *)session {
    self.tipLabel.text = @"会话中断";
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    self.tipLabel.text = @"会话中断结束，已重置会话";
    [self.scnView.session runWithConfiguration:self.sessionConfig options:ARSessionRunOptionResetTracking];
    self.aligned = NO;
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    switch (error.code) {
        case ARErrorCodeUnsupportedConfiguration:
        {
            self.tipLabel.text = @"当前设备不支持";
        } break;
        case ARErrorCodeSensorUnavailable:
        {
            self.tipLabel.text = @"传感器不可用";
        } break;
        case ARErrorCodeSensorFailed:
        {
            self.tipLabel.text = @"传感器出错";
        } break;
        case ARErrorCodeCameraUnauthorized:
        {
            self.tipLabel.text = @"相机不可用";
        } break;
        case ARErrorCodeWorldTrackingFailed:
        {
            self.tipLabel.text = @"跟踪出错，请重置";
        } break;
        default:
            break;
    }
}

#pragma mark - 平面检测代理
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    //判断场景内添加的锚点是否为平面锚点
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        PlaneNode *node = [PlaneNode planeNodeWithAnchor:(ARPlaneAnchor *)anchor];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tipLabel.text = @"检测到平面并已添加到场景中，点击屏幕可刷新会话";
        });
        return node;
    }
    return nil;
}

- (void)renderer:(id<SCNSceneRenderer>)renderer willUpdateNode:(nonnull SCNNode *)node forAnchor:(nonnull ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        [(PlaneNode *)node updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tipLabel.text = @"场景内平面有更新";
        });
    }
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
        [(PlaneNode *)node removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tipLabel.text = @"场景内平面被移除";
        });
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    /*
     magneticHeading 设备与磁北的相对角度
     trueHeading 设置与真北的相对角度, 必须和定位一起使用, iOS需要设置的位置来计算真北
     真北始终指向地理北极点
     */
    //    NSLog(@"********************%f", newHeading.magneticHeading);
    
    // 1.将获取到的角度转为弧度 = (角度 * π) / 180;
    CGFloat angle = newHeading.magneticHeading * M_PI / 180.0;
    
    //    NSLog(@"angle -------  角度------- %f",angle);
    // 2.旋转图片
    /*
     顺时针 正
     逆时针 负数
     */
    //    self.compasspointer.transform = CGAffineTransformIdentity;
    self.compasspointer.transform = CGAffineTransformMakeRotation(-angle);
    
    if (!self.aligned) {
        self.aligned = YES;
        SCNMatrix4 transform = SCNMatrix4MakeTranslation(0, -1.5, 0);
        transform = SCNMatrix4Rotate(transform, angle, 0, 1, 0);
        self.floor.transform = transform;
        //        [self updateRoute];
    }
}

#pragma mark - lazy
- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.frame = CGRectMake(0, 64, CGRectGetWidth(self.scnView.frame), 50);
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor blackColor];
    }
    return _tipLabel;
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _maskView.backgroundColor = [UIColor whiteColor];
        _maskView.alpha = 0.6;
    }
    return _maskView;
}

- (ARSCNView *)scnView {
    if (!_scnView) {
        _scnView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    }
    return _scnView;
}

- (ARConfiguration *)sessionConfig {
    if (!_sessionConfig) {
        //        if ([ARWorldTrackingConfiguration isSupported]) {
        //            //创建可跟踪的6DOF的会话配置
        //            ARWorldTrackingConfiguration *worldConfig = [ARWorldTrackingConfiguration new];
        ////            worldConfig.planeDetection = ARPlaneDetectionHorizontal;
        //            worldConfig.worldAlignment = ARWorldAlignmentGravity;
        //            worldConfig.lightEstimationEnabled = YES;
        //            _sessionConfig = worldConfig;
        //        }else {
        //创建可跟踪3DOF的会话配置
        AROrientationTrackingConfiguration *orientationConfig = [AROrientationTrackingConfiguration new];
        orientationConfig.worldAlignment = ARWorldAlignmentGravity;
        _sessionConfig = orientationConfig;
        self.tipLabel.text = @"6DOF unsupported";
        //        }
    }
    return _sessionConfig;
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (UIImageView *)compasspointer {
    if (!_compasspointer) {
        _compasspointer = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timg@2x.jpg"]];
        _compasspointer.frame = CGRectMake(0, 0, 50, 50);
        _compasspointer.center = CGPointMake(self.view.center.x, CGRectGetMaxY(self.view.frame)-50);
    }
    return _compasspointer;
}

- (SCNNode *)floor {
    if (!_floor) {
        _floor = [SCNNode new];
        //        _floor.geometry = [SCNPlane planeWithWidth:10 height:10];
        //        [_floor setPosition:SCNVector3Make(0, 0, 0)];
        //
        //        _floor.geometry.firstMaterial.multiply.contents = [UIImage imageNamed:@"plane"];
        //        _floor.geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"plane"];
        //        _floor.geometry.firstMaterial.multiply.intensity = 0.5;
        //        _floor.geometry.firstMaterial.lightingModelName = SCNLightingModelConstant;
        //
        //        _floor.geometry.firstMaterial.multiply.wrapS =
        //        _floor.geometry.firstMaterial.diffuse.wrapS  =
        //        _floor.geometry.firstMaterial.multiply.wrapT =
        //        _floor.geometry.firstMaterial.diffuse.wrapT  = SCNWrapModeRepeat;
        
        //获取模型场景
        SCNScene *scene = [SCNScene sceneNamed:@"Plane.scn"];
        _floor = [scene.rootNode clone];
        _floor.position = SCNVector3Make(0, 0, 0);
        //        SCNMatrix4 transform = SCNMatrix4MakeTranslation(0, -1.5, 0);
        //        transform = SCNMatrix4Rotate(transform, M_PI_2, 0, -1, 0);
        //        _floor.transform = transform;
    }
    return _floor;
}
//
//- (NSMutableArray *)routes {
//    if (!_routes) {
//        _routes = [[NSMutableArray alloc] initWithObjects:@[@0.0,@1.0],
//                   @[@1.0,@1.0],
//                   @[@1.0,@0.0],
//                   @[@1.0,@-1.0],
//                   @[@0.0,@-1.0],
//                   @[@-1.0,@-1.0],
//                   @[@-1.0,@0.0],
//                   @[@-1.0,@1.0],nil];
//    }
//    return _routes;
//}

- (void)setRoutes:(NSMutableArray *)routes {
    if (![self.view superview]) {
        return;
    }
    _routes = routes;
    if (self.aligned) {
        [self updateRoute];
    }
}

- (NSMutableArray *)routeNodes {
    if (!_routeNodes) {
        _routeNodes = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < 10; i++) {
            SCNVector3 vector3 = SCNVector3Make(self.floor.worldTransform.m41, self.floor.worldTransform.m42, self.floor.worldTransform.m43);
            //获取模型场景
            SCNScene *scene = [SCNScene sceneNamed:@"Cylinder.scn"];
            SCNNode *node = [scene.rootNode clone];
            node.position = vector3;
            [self.floor addChildNode:node];
            [_routeNodes addObject:node];
        }
    }
    return _routeNodes;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
