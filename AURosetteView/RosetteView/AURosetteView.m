//
//  AURosetteView.m
//  DigitalPublishing
//
//  Created by Emil Wojtaszek on 22.06.2012.
//
//

//Views
#import "AURosetteView.h"
#import <CoreImage/CoreImage.h>

@interface AURosetteView (Private)
- (void)wheelButtonAction:(id)sender;
- (void)tapAction:(UITapGestureRecognizer*)tapGestureRecognizer;
- (void)addLeaves;
- (void)addImages;
- (void)expand;
- (void)fold;
@end

@implementation AURosetteView
@synthesize on = _on;
@synthesize wheelButton = _wheelButton;
@synthesize offImage = _offImage;
@synthesize onImage = _onImage;

#define kOnImageName @"button_orb.png"
#define kOffImageName @"button_orb.png"
//#define kLeafImageName @"/Bundle.bundle/Resources/rosetta_leaf.png"
#define kLeafImageName @"rosetta_leaf.png"

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithItems:(NSArray*)items {
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 234.0f, 164.0f)];
    if (self) {
        _items = items;
		
        // set default
        _on = NO;
        
        // recognize taps when wheel is expanded
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(tapAction:)];
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_tapGestureRecognizer];
        
        // array containing leaves layers
        _leavesLayers = [NSMutableArray new];
        _imagesLayers = [NSMutableArray new];
        
        // add leaves layers
        [self addLeaves];
        
        // add images
        [self addImages];
        
        // add button
        _wheelButton = [[UIButton alloc] init];
        [_wheelButton setBackgroundImage:self.offImage forState:UIControlStateNormal];
		[_wheelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
		[_wheelButton.titleLabel setTextColor:[UIColor whiteColor]];
		[_wheelButton.titleLabel setShadowColor:[UIColor blackColor]];
		
        [self addSubview:_wheelButton];
        
        // add target
        [_wheelButton addTarget:self action:@selector(wheelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        // Others settings
        [self setExclusiveTouch:NO];
        [self setBackgroundColor:[UIColor clearColor]];
	}
    return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    CGRect rect = self.bounds;
    _wheelButton.frame = CGRectMake(CGRectGetMidX(rect) - 37.5f,
                                    rect.size.height - 67.0f, 75.0, 67.0f);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)toggleWithAnimation:(BOOL)animated {
    [self setOn:!_on animated:animated];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setOn:(BOOL)on animated:(BOOL)animated {
	[self willChangeValueForKey:@"on"];
    _on = on;
    
    if (_on) {
        
        [_wheelButton setBackgroundImage:self.onImage forState:UIControlStateNormal];
        
        // expand rosette
        [self expand];
        
        // enable tap gesture recognizer
        _tapGestureRecognizer.enabled = YES;
    } else {
		
        [_wheelButton setBackgroundImage:self.offImage forState:UIControlStateNormal];
        
        // fold rosette
        [self fold];
        
        // disable tap gesture recognizer
        _tapGestureRecognizer.enabled = NO;
    }
	[self didChangeValueForKey:@"on"];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if (_on) {
		UIView *hitView = [super hitTest:point withEvent:event];
		return hitView;
	} else {
		UIView *hitView = [super hitTest:point withEvent:event];
		
		// If the hitView is THIS view, return nil and allow hitTest:withEvent: to
		// continue traversing the hierarchy to find the underlying view.
		if (hitView == self) {
			return nil;
		}
		// Else return the hitView (as it could be one of this view's buttons):
		return hitView;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setImages:(NSArray *)images {
    // add leaves
    [self addLeaves];
    
    // add images
    [self addImages];
}

- (UIImage *)offImage
{
	if (!_offImage) {
		_offImage = [UIImage imageNamed:kOffImageName];
	}
	return _offImage;
}

- (void)setOffImage:(UIImage *)offImage
{
	if (![offImage isEqual:_offImage]) {
		_offImage = offImage;
		if (!_on) {
			[_wheelButton setBackgroundImage:_offImage forState:UIControlStateNormal];
		}
	}
}

- (UIImage *)onImage
{
	if (!_onImage) {
		_onImage = [UIImage imageNamed:kOnImageName];
	}
	return _onImage;
}

- (void)setOnImage:(UIImage *)onImage
{
	if (![onImage isEqual:_onImage]) {
		_onImage = onImage;
		if (_on) {
			[_wheelButton setBackgroundImage:_onImage forState:UIControlStateNormal];
		}
	}
}

- (void)setForegroundImage:(UIImage *)image
{
	[_wheelButton setImage:image forState:UIControlStateNormal];
	[_wheelButton setImage:image forState:UIControlStateSelected];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	if (_on) {
		// test if our control subview is on-screen
		if (_wheelButton.superview != nil) {
			if ([touch.view isDescendantOfView:_wheelButton]) {
				// we touched our control surface
				return NO; // ignore the touch
			}
		}
		
		return YES; // handle the touch
	} else {
		return NO;
	}
}
@end


@implementation AURosetteView (Private)

////////////////////////////////////////////////////////////////////////////////////////////////////
static inline CGFloat DegreesToRadians(CGFloat inValue) {
    return (inValue * (180.0f / (CGFloat)M_PI));
}

static inline CGFloat RadiansToDegrees(CGFloat inValue) {
    return (inValue * ((CGFloat)M_PI / 180.0f));
}

CGFloat const kApertureAngle = 43.0f;

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addImages {
    // remove from superlayer
    [_imagesLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	
    // clean array
    [_imagesLayers removeAllObjects];
    
    // iterate all images
    
    [_items enumerateObjectsUsingBlock:^(AURosetteItem* obj, NSUInteger idx, BOOL *stop) {
        // set content image
        UIImage* image = [obj normalImage];
        
        // add image layer (image with facebook or twitter)
        CALayer* imageLayer = [CALayer layer];
        
        //        CIImage* iii = [CIImage imageWithCGImage:image.CGImage];
        //
        //        CIFilter *filter = [CIFilter filterWithName:@"CIGloom"
        //                                      keysAndValues: kCIInputImageKey, iii, nil];
        //        CIImage *outputImage = [filter outputImage];
        //
        //        CIContext *context = [CIContext contextWithOptions:nil];
        //
        //        CGImageRef cgimg =
        //        [context createCGImage:outputImage fromRect:[outputImage extent]];
        //        UIImage *newImg = [UIImage imageWithCGImage:cgimg];
        
        
        imageLayer.contents = (id)image.CGImage;
        imageLayer.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
        imageLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
        imageLayer.position = CGPointMake(CGRectGetMidX(self.bounds), self.bounds.size.height - 44.0f);
        imageLayer.transform = CATransform3DMakeScale(0.01f, 0.01f, 1.0f);
        imageLayer.opacity = 0.6f;
        
        [self.layer addSublayer:imageLayer];
        [_imagesLayers addObject:imageLayer];
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addLeaves {
    // remove from superlayer
    [_leavesLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	
    // clean array
    [_leavesLayers removeAllObjects];
	
    // iterate all images
    [_items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        // get image
        UIImage *image = [UIImage imageNamed:kLeafImageName];
        
        // create new layer
        CALayer* layer = [CALayer layer];
        
        // set up layer
        layer.contents = (id)image.CGImage;
        layer.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
        layer.anchorPoint = CGPointMake(0.0f, 0.5f);
        layer.position = CGPointMake(CGRectGetMidX(self.bounds), self.bounds.size.height - 44.0f);
        layer.transform = CATransform3DMakeScale(0.15f, 0.15f, 1.0f);
		
        // add layer
        [self.layer addSublayer:layer];
        [_leavesLayers addObject:layer];
    }];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)wheelButtonAction:(id)sender {
    [self toggleWithAnimation:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)tapAction:(UITapGestureRecognizer*)tapGestureRecognizer {
	
	CGPoint point = [tapGestureRecognizer locationInView:self];
    for (int idx = 0; idx < [_leavesLayers count]; idx++) {
		CALayer *leafLayer = [_leavesLayers objectAtIndex:idx];
		AURosetteItem *obj = [_items objectAtIndex:idx];
		if ([[leafLayer presentationLayer] hitTest:point] || [leafLayer hitTest:point]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [obj.target performSelector:obj.action withObject:self];
#pragma clang diagnostic pop
        }
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)expand {
    //CGFloat angle_ = DegreesToRadians(kApertureAngle);
    
    [CATransaction begin];
    
    // restore proper scale and rotation
    for (NSInteger i=0; i<[_items count]; i++) {
        
        CALayer* layer = nil;
        //CGFloat angle = (angle_ * i) + DegreesToRadians(0.4);
		CGFloat angle = (-1.0 * (M_PI / 2.0) * i);
		if (i == 0) {
			angle = ((-1.0 * (M_PI / 2.0)) / 3);
		} else if (i == 2) {
			angle = angle + ((1.0 * (M_PI / 2.0)) / 3);
		}
		
		CATransform3D transform = CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
        
        CABasicAnimation* leafAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [leafAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [leafAnimation setToValue:[NSValue valueWithCATransform3D:transform]];
        [leafAnimation setFillMode:kCAFillModeForwards];
        [leafAnimation setRemovedOnCompletion: NO];
        [leafAnimation setDuration:0.3f];
        
        layer = [_leavesLayers objectAtIndex:i];
		[layer removeAnimationForKey:@"fold"];
        [layer addAnimation:leafAnimation forKey:@"expand"];
        
        CABasicAnimation* scaleImageAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [scaleImageAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [scaleImageAnimation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0f, 1.0f, 1.0f)]];
        [scaleImageAnimation setFillMode:kCAFillModeForwards];
        [scaleImageAnimation setRemovedOnCompletion: NO];
        
        CGPoint point = CGPointMake(0.85*97.0f * cos(angle) + CGRectGetMidX(self.bounds), 0.85*97.0f * sin(angle) + self.bounds.size.height - 44.0);
        CABasicAnimation* positionImageAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        [positionImageAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [positionImageAnimation setToValue:[NSValue valueWithCGPoint:point]];
        [positionImageAnimation setFillMode:kCAFillModeForwards];
        [positionImageAnimation setRemovedOnCompletion: NO];
        
        CAAnimationGroup* group = [CAAnimationGroup animation];
        [group setAnimations:[NSArray arrayWithObjects:scaleImageAnimation, positionImageAnimation, nil]];
        [group setFillMode:kCAFillModeForwards];
        [group setRemovedOnCompletion: NO];
        [group setDuration:0.15f];
        [group setBeginTime:CACurrentMediaTime () + 0.27f];
        
        layer = [_imagesLayers objectAtIndex:i];
        [layer addAnimation:group forKey:@"show"];
        
    }
    
    [CATransaction commit];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fold {
    
    [CATransaction begin];
    
    // restore proper scale and rotation
    for (NSInteger i=0; i<[_items count]; i++) {
        
        CATransform3D transform = CATransform3DConcat(CATransform3DMakeScale(0.15f, 0.15f, 1.0f),
                                                      CATransform3DIdentity);
        
        CABasicAnimation* leafAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [leafAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        [leafAnimation setToValue:[NSValue valueWithCATransform3D:transform]];
        [leafAnimation setFillMode:kCAFillModeForwards];
        [leafAnimation setRemovedOnCompletion: NO];
        [leafAnimation setDuration:0.3f];
        [leafAnimation setBeginTime:CACurrentMediaTime () + 0.1f];
        
        CALayer* layer = [_leavesLayers objectAtIndex:i];
		//[layer removeAnimationForKey:@"expand"];
        [layer addAnimation:leafAnimation forKey:@"fold"];
        
        CABasicAnimation* scaleImageAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [scaleImageAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        [scaleImageAnimation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.01f, 0.01f, 1.0f)]];
        [scaleImageAnimation setFillMode:kCAFillModeForwards];
        [scaleImageAnimation setRemovedOnCompletion: NO];
        
        CGPoint point = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        CABasicAnimation* positionImageAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        [positionImageAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        [positionImageAnimation setToValue:[NSValue valueWithCGPoint:point]];
        [positionImageAnimation setFillMode:kCAFillModeForwards];
        [positionImageAnimation setRemovedOnCompletion: NO];
        
        CAAnimationGroup* group = [CAAnimationGroup animation];
        [group setAnimations:[NSArray arrayWithObjects:scaleImageAnimation, positionImageAnimation, nil]];
        [group setFillMode:kCAFillModeForwards];
        [group setRemovedOnCompletion: NO];
        [group setDuration:0.15f];
        
        layer = [_imagesLayers objectAtIndex:i];
        [layer addAnimation:group forKey:@"hide"];
        
    }
    
    [CATransaction commit];
}


@end
