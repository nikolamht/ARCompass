//
//  WalkViewController.m
//  ARAddModel
//
//  Created by miaoht on 2018/7/4.
//  Copyright © 2018年 miaoht. All rights reserved.
//

#import "WalkViewController.h"
#import "LocalCoordinate.h"

#import <ARKit/ARKit.h>
#import "PlaneNode.h"
#import <CoreLocation/CoreLocation.h>
#import <math.h>

@interface WalkViewController () <CLLocationManagerDelegate,ARSessionDelegate,ARSCNViewDelegate>
@property (nonatomic, assign) BOOL currentNaviRouteChanged;
@property (nonatomic, strong) AMapNaviPoint *originLocation;//地图原点
//----------------------------------------------------------
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

//地面
@property(nonatomic , strong) SCNNode *floor;

@property(nonatomic , assign) CGFloat pinAngle;
//
@property(nonatomic , strong) SCNView *dashboardScnView;
@property(nonatomic , strong) SCNNode *dashboardPinNode;
@property(nonatomic , strong) SCNNode *dashboardNode;
@property(nonatomic , strong) SCNNode *pinNode;
@property(nonatomic , strong) SCNText *degreeText;
@property(nonatomic , strong) SCNNode *degree;
@end

@implementation WalkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    [self.view addSubview:self.scnView];
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.tipLabel];
    self.scnView.delegate = self;
    self.scnView.session.delegate = self;
    //显示fps信息
//    self.scnView.showsStatistics = YES;
    //显示检测到的特征点
//    self.scnView.debugOptions = ARSCNDebugOptionShowWorldOrigin;
    [self.scnView.scene.rootNode addChildNode:self.floor];
    
    [self.view addSubview:self.dashboardScnView];
    
//    [self placeDestination];
    
//    [self.view addSubview:self.compasspointer];
    
    //管理者的代理
    self.locationManager.delegate = self;
    // 开始获取用户位置 注意:获取用户的方向信息是不需要用户授权的
    [self.locationManager startUpdatingHeading];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle    = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationController.toolbar.barStyle      = UIBarStyleBlack;
    self.navigationController.toolbar.translucent   = YES;
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    [self.scnView.session runWithConfiguration:self.sessionConfig options:ARSessionRunOptionResetTracking];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scnView.session pause];
}

#pragma mark - ARSessionDelegate
- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
//    NSLog(@"%@",[NSString stringWithFormat:@"%f %f %f",frame.camera.eulerAngles[0],frame.camera.eulerAngles[1],frame.camera.eulerAngles[2]]);
    SCNMatrix4 transform = SCNMatrix4MakeRotation(self.pinAngle+M_PI, 0,0,1);
    transform = SCNMatrix4Rotate(transform,M_PI_2, -1, 0, 0);
    transform = SCNMatrix4Rotate(transform, M_PI_4, 0, 1, 0);
    transform = SCNMatrix4Scale(transform, 0.5, 0.5, 0.5);
    transform = SCNMatrix4Rotate(transform, -frame.camera.eulerAngles[0], 1, 0, -1);
    transform = SCNMatrix4Translate(transform, 1.0, 0, 1.0);
    self.dashboardNode.transform = transform;
    
    SCNMatrix4 pinTransform = SCNMatrix4MakeRotation(M_PI, 0,0,1);
    pinTransform = SCNMatrix4Scale(pinTransform,0.1, 0.125, 0.1);
    pinTransform = SCNMatrix4Rotate(pinTransform,M_PI_2, -1, 0, 0);
    pinTransform = SCNMatrix4Rotate(pinTransform, M_PI_4, 0, 1, 0);
    pinTransform = SCNMatrix4Rotate(pinTransform, -frame.camera.eulerAngles[0], 1, 0, -1);
    pinTransform = SCNMatrix4Translate(pinTransform, 1.0, 0.01, 1.0);

    self.pinNode.transform = pinTransform;
    
    if (self.dashboardScnView.hidden) {
        self.dashboardScnView.hidden = NO;
    }
}

#pragma mark - session代理
- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera {
    switch (camera.trackingState) {
        case ARTrackingStateNotAvailable:
        {
            self.tipLabel.text = @"跟踪不可用";
            // self.aligned = NO;
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.7;
            }];
        } break;
        case ARTrackingStateLimited:
        {
            //            self.aligned = NO;
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
    //    self.aligned = NO;
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
    self.pinAngle = newHeading.magneticHeading * M_PI / 180.0;
    
    self.degreeText.string = [NSString stringWithFormat:@"%.0f°",newHeading.magneticHeading];
    SCNMatrix4 transform = SCNMatrix4MakeTranslation(0.3, 0.3, 0.01);
    transform = SCNMatrix4Scale(transform, -0.03, -0.03, 0.03);
    self.degree.transform = transform;
    
//    NSLog(@"angle -------  角度------- %f",angle);
    // 2.旋转图片
    /*
     顺时针 正
     逆时针 负数
     */
    //    self.compasspointer.transform = CGAffineTransformIdentity;
//    self.compasspointer.transform = CGAffineTransformMakeRotation(-angle);
    
}

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
        _sessionConfig = [AROrientationTrackingConfiguration new];
        _sessionConfig.worldAlignment = ARWorldAlignmentGravityAndHeading;
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

//- (UIImageView *)compasspointer {
//    if (!_compasspointer) {
//        _compasspointer = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timg@2x.jpg"]];
//        _compasspointer.frame = CGRectMake(0, 0, 50, 50);
//        _compasspointer.center = CGPointMake(self.view.center.x, CGRectGetMaxY(self.view.frame)-50);
//    }
//    return _compasspointer;
//}

- (SCNNode *)floor {
    if (!_floor) {
        _floor = [SCNNode new];
        //获取模型场景
        SCNScene *scene = [SCNScene sceneNamed:@"Plane.scn"];
        _floor = [scene.rootNode clone];
        _floor.position = SCNVector3Make(0, -1.1, 0);
    }
    return _floor;
}

- (SCNNode *)dashboardNode {
    if (!_dashboardNode) {
        for (SCNNode *node in [self.dashboardPinNode childNodes]) {
            if ([node.name isEqualToString:@"dash"]) {
                _dashboardNode = node;
                break;
            }
        }
    }
    return _dashboardNode;
}

- (SCNNode *)pinNode {
    if (!_pinNode) {
        for (SCNNode *node in [self.dashboardPinNode childNodes]) {
            if ([node.name isEqualToString:@"pin"]) {
                _pinNode = node;
                break;
            }
        }
    }
    return _pinNode;
}

- (SCNView *)dashboardScnView{
    if(!_dashboardScnView) {
        _dashboardScnView = [[SCNView alloc] initWithFrame:self.view.bounds];
        _dashboardScnView.userInteractionEnabled = NO;
        SCNScene *scene = [SCNScene scene];
        [scene.rootNode addChildNode:self.dashboardPinNode];
        _dashboardScnView.backgroundColor = [UIColor clearColor];
        _dashboardScnView.hidden = YES;
        _dashboardScnView.scene = scene;
    }
    return _dashboardScnView;
}

- (SCNNode *)dashboardPinNode {
    if (!_dashboardPinNode) {
        _dashboardPinNode = [[SCNScene sceneNamed:@"dashboard.scn"].rootNode clone];
    }
    return _dashboardPinNode;
}

- (SCNText *)degreeText {
    if (!_degreeText) {
                // 设置几何形状，我们选择立体字体
                _degreeText = [SCNText textWithString:@"0°" extrusionDepth:0.01];
                // 设置字体颜色
                _degreeText.firstMaterial.diffuse.contents = [UIColor whiteColor];
                // 设置字体大小
                _degreeText.font = [UIFont systemFontOfSize:10];
    }
    return _degreeText;
}

- (SCNNode *)degree {
    if (!_degree) {
        _degree = [SCNNode node];
        _degree.geometry = self.degreeText;
        [self.pinNode addChildNode:_degree];
    }
    return _degree;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


+ (UIImage *)getImage:(NSString *)name withDistance:(NSString *)dis{
    CGSize size = [self sizeWithText:name withFont:[UIFont systemFontOfSize:200]];
    
    CGRect outrect = CGRectMake(0, 0, size.width+50, size.height+200);
    CGRect innerrect = CGRectMake(25, 25, size.width, size.height);
    CGRect bottomrect = CGRectMake(0, size.height+50, size.width+50, 150);
    
    UIGraphicsBeginImageContext(outrect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [[UIColor lightGrayColor] CGColor]);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:outrect cornerRadius:50];
    
    CGContextAddPath(context, bezierPath.CGPath);
    CGContextFillPath(context);
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter; //文字的属性
    NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:200],NSParagraphStyleAttributeName:style,NSForegroundColorAttributeName:[UIColor whiteColor]}; //将文字绘制上去
    [name drawInRect:innerrect withAttributes:dic]; //4.获取绘制到得图片
    
    CGContextRestoreGState(context);
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    UIBezierPath *bezier = [UIBezierPath bezierPathWithRoundedRect:bottomrect byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(50, 50)];
    
    CGContextAddPath(context, bezier.CGPath);
    CGContextFillPath(context);
    
    NSMutableParagraphStyle *s = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    s.alignment = NSTextAlignmentCenter; //文字的属性
    NSDictionary *d = @{NSFontAttributeName:[UIFont systemFontOfSize:120],NSParagraphStyleAttributeName:style,NSForegroundColorAttributeName:[UIColor lightGrayColor]}; //将文字绘制上去
    [dis drawInRect:bottomrect withAttributes:d]; //4.获取绘制到得图片
    
    CGContextRestoreGState(context);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
//随机颜色
+ (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );
    //0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;
    // 0.5 to 1.0,away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

+ (CGSize)sizeWithText:(NSString *)text withFont:(UIFont *)font{
    CGSize size = [text sizeWithAttributes:@{NSFontAttributeName:font}];
    return size;
}

+ (NSString *)getDistanceString:(double)dis {
    NSString *str = @"";
    if (dis > 1000.0) {
        str = [NSString stringWithFormat:@"%.1fkm",dis/1000.0];
    }else {
        str = [NSString stringWithFormat:@"%.0fm",dis];
    }
    return str;
}

@end
