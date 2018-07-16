//
//  PlaneNode.h
//  ARAddModel
//
//  Created by miaoht on 2018/6/12.
//  Copyright © 2018年 miaoht. All rights reserved.
//

#import <SceneKit/SceneKit.h>
@class ARPlaneAnchor;
@interface PlaneNode : SCNNode
+ (instancetype)planeNodeWithAnchor:(ARPlaneAnchor *)anchor ;
- (void)updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor ;
- (void)removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor ;
@end
