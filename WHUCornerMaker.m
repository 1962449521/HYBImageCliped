//
//  WHUCornerMasker.m
//  CornerViewDemo
//
//  Created by 胡 帅 on 16/4/7.
//  Copyright © 2016年 Disney. All rights reserved.
//

#import "WHUCornerMaker.h"

#pragma mark - 重用池的键值标识自定义对象

@interface WHUCornerKey : NSObject<NSCopying>

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat radius;

@end

@implementation WHUCornerKey

- (instancetype)initWithColor:(UIColor *)color radius:(CGFloat) radius {
    self = [super init];
    if (self) {
        _color = color;
        _radius = radius;
    }
    return self;
}

- (BOOL)isEqual:(WHUCornerKey *)other {
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[self class]]) {
        return NO;
    } else {
        return CGColorEqualToColor(_color.CGColor, other.color.CGColor) &&  fabs(_radius - other.radius) < 0.1;
    }
}

- (NSUInteger)hash {
    
    const CGFloat *colors = CGColorGetComponents(_color.CGColor);
    NSUInteger count = CGColorGetNumberOfComponents(_color.CGColor);
    
    NSMutableString *mStr = [NSMutableString string];
    for (NSUInteger index = 0; index < count; index ++) {
        [mStr appendString:[NSString stringWithFormat:@"%@", @(colors[index])]];
    }
    [mStr appendString:[NSString stringWithFormat:@"%@", @(_radius)]];
    
    return [mStr hash];
}

- (id)copyWithZone:(NSZone *)zone {
    WHUCornerKey *instance =  [[[self class] allocWithZone:zone] init];
    if (instance) {
        instance.color = _color;
        instance.radius = _radius;
    }
    return instance;
}

@end

#pragma mark - 被添加的圆角覆盖物标识

@interface WHUCornerImageView:UIImageView

@end

@implementation WHUCornerImageView

@end

#pragma mark - 主功能实现

@interface WHUCornerMaker ()

#pragma mark 实现享元模式所需的重用池
@property (nonatomic, strong) NSMutableDictionary<WHUCornerKey *, UIImage *> *cornerPool;
@property (nonatomic, strong) NSMutableDictionary<WHUCornerKey *, NSArray<UIImage *> *> *cornerRectPool;

#pragma mark 创建或获取可重用的圆角图片
- (UIImage *) p_cornerWithColor:(UIColor *)color radius:(CGFloat) radius;
- (NSArray<UIImage *> *) p_cornersWithColor:(UIColor *)color radius:(CGFloat) radius;

@end

@implementation WHUCornerMaker

#pragma mark 提供调用接口
+ (BOOL) isCorneredAtView:(UIView *)view {
    __block BOOL isCornered;
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[WHUCornerImageView class]]) {
            isCornered = YES;
            *stop = YES;
        }
    }];
    return isCornered;
}

- (void) roundView:(UIView *) view withCornerRadius:(CGFloat) radius defaultColor:( UIColor * _Nullable)defaultcolor byRoundingCorners:(UIRectCorner)corners {
    [[view subviews] enumerateObjectsUsingBlock:^( UIView *  obj, NSUInteger idx, BOOL *  stop) {
        if ( [obj isKindOfClass:[WHUCornerImageView class]]) {
            [obj removeFromSuperview];
        }
    }];
    
    UIView *superview = view.superview;
    while (superview.backgroundColor == nil || CGColorEqualToColor(superview.backgroundColor.CGColor, [UIColor clearColor].CGColor)) {
        if (!superview) {
            break;
        }
        superview = [superview superview];
    }
    UIColor *color = superview.backgroundColor;
    if (!color) {
        color = defaultcolor;
    }
    
    NSArray *arr = [self p_cornersWithColor:color radius:radius];
    if ([arr count] < 4) {
        return;
    }
    
    CGFloat value1 = CGRectGetWidth(view.frame) - radius / 2.0;
    CGFloat value2 = radius / 2.0;
    CGFloat value3 = CGRectGetHeight(view.frame) - radius / 2.0;

    
    if (corners & UIRectCornerTopLeft) {
        WHUCornerImageView *leftUpImageView = [[WHUCornerImageView alloc]initWithImage:arr[0]];
        leftUpImageView.center = CGPointMake(value2, value2);
        [view addSubview:leftUpImageView];
    }
    
    if (corners & UIRectCornerTopRight) {
        WHUCornerImageView *rightUpImageView = [[WHUCornerImageView alloc]initWithImage:arr[1]];
        rightUpImageView.center = CGPointMake(value1, value2);
        [view addSubview:rightUpImageView];
    }
    
    if (corners & UIRectCornerBottomRight) {
        WHUCornerImageView *rightDownImageView = [[WHUCornerImageView alloc]initWithImage:arr[2]];
        rightDownImageView.center = CGPointMake(value1, value3);
        [view addSubview:rightDownImageView];

    }
    
    if (corners & UIRectCornerBottomLeft) {
        WHUCornerImageView *leftDownImageView = [[WHUCornerImageView alloc]initWithImage:arr[3]];
        leftDownImageView.center = CGPointMake(value2, value3);
        [view addSubview:leftDownImageView];
    }
}

- (void) roundViews:(NSArray<UIView *> *) views withCornerRadius:(CGFloat) radius defaultColor:(UIColor * _Nullable)color  byRoundingCorners:(UIRectCorner)corners {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        [self roundView:view withCornerRadius:radius defaultColor:color byRoundingCorners:corners];
    }];
}

- (void) roundView:(UIView *) view withCornerRadius:(CGFloat) radius defaultColor:(UIColor * _Nullable)color{
    [self roundView:view withCornerRadius:radius defaultColor:color byRoundingCorners:UIRectCornerAllCorners];
}

- (void) roundViews:(NSArray<UIView *> *) views withCornerRadius:(CGFloat) radius defaultColor:(UIColor * _Nullable)color {
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        [self roundView:view withCornerRadius:radius defaultColor:color];
    }];
}

#pragma mark 私有方法
- (UIImage *) p_cornerWithColor:(UIColor *)color radius:(CGFloat) radius {
    if (!_cornerPool) {
        _cornerPool = [NSMutableDictionary dictionary];
    }
    WHUCornerKey *key = [[WHUCornerKey alloc] initWithColor:color radius:radius];
    
    if (![self.cornerPool objectForKey:key]) {
        UIImage *img;
        radius *= [UIScreen mainScreen].scale ;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef contextRef = CGBitmapContextCreate(NULL, radius, radius, 8, 4 * radius, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
        
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        CGContextMoveToPoint(contextRef, radius, 0);
        CGContextAddLineToPoint(contextRef, 0, 0);
        CGContextAddLineToPoint(contextRef, 0, radius);
        CGContextAddArc(contextRef, radius, radius, radius, 180 * (M_PI / 180.0f), 270 * (M_PI / 180.0f), 0);
        CGContextFillPath(contextRef);
        
        CGImageRef imageCG = CGBitmapContextCreateImage(contextRef);
        img = [UIImage imageWithCGImage:imageCG];
        
        CGContextRelease(contextRef);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(imageCG);
        if (img) {
            [self.cornerPool setObject:img forKey:key];
            return img;
        }
    }
    return (UIImage *) [self.cornerPool objectForKey:key];
}

- (NSArray<UIImage *> *) p_cornersWithColor:(UIColor *)color radius:(CGFloat) radius {
    if (!_cornerRectPool) {
        _cornerRectPool = [NSMutableDictionary dictionary];
    }
    WHUCornerKey *key = [[WHUCornerKey alloc] initWithColor:color radius:radius];

    if (![self.cornerRectPool objectForKey:key]) {
        UIImage *cornerImage = [self p_cornerWithColor:color radius:radius];
        CGImageRef imageRef = cornerImage.CGImage;
        
        UIImage *leftUpImage = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale  orientation:UIImageOrientationRight];
        UIImage *rightUpImage = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale  orientation:UIImageOrientationLeftMirrored];
        UIImage *rightDownImage = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale  orientation:UIImageOrientationLeft];
        UIImage *leftDownImage = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale  orientation:UIImageOrientationUp];;
        
        if (leftUpImage && rightUpImage && rightDownImage && leftDownImage) {
            NSArray *cornerRect = @[leftUpImage, rightUpImage, rightDownImage, leftDownImage];
            [self.cornerRectPool setObject:cornerRect forKey:key];
            return cornerRect;
        } else {
            return nil;
        }
        
    }
    return (NSArray<UIImage *> *)[self.cornerRectPool objectForKey:key];
}


@end
