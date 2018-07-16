//
//  PlaneNode.m
//  ARAddModel
//
//  Created by miaoht on 2018/6/12.
//  Copyright © 2018年 miaoht. All rights reserved.
//

#import "PlaneNode.h"
#import <ARKit/ARKit.h>

@implementation PlaneNode

+ (instancetype)planeNodeWithAnchor:(ARPlaneAnchor *)anchor {
    PlaneNode *node = [[PlaneNode alloc] init];
    if (node) {
        //创建材质
        SCNMaterial *material = [[SCNMaterial alloc] init];
        material.diffuse.contents = [UIImage imageNamed:@"plane"];
        //创建平面
        SCNPlane *planeGeometry = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
        planeGeometry.materials = @[material];
        //创建节点并作为当前节点的子节点
        SCNNode *childNode = [SCNNode nodeWithGeometry:planeGeometry];
        childNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
        childNode.transform = SCNMatrix4MakeRotation(-M_PI_2, 1.0, 0.0, 0.0);
        [node addChildNode:childNode];
    }
    return node;
}

- (void)updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor {
    //更新平面范围
    SCNNode *node = [self.childNodes firstObject];
    SCNPlane *planeGeometry = (SCNPlane *)node.geometry;
    planeGeometry.width = anchor.extent.x;
    planeGeometry.height = anchor.extent.z;
    node.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
}

- (void)removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor {
    //删除节点
    [self removeFromParentNode];
}

@end
