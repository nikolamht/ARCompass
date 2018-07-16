//
//  LocalCoordinate.h
//  ARAddModel
//
//  Created by miaoht on 2018/7/4.
//  Copyright © 2018年 miaoht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface LocalCoordinate : NSObject
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic,   copy) NSString *name;
@end
