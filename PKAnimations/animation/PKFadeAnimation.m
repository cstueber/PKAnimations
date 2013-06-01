/*
 * Copyright (c) 2013 Patrick Kulling
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PKFadeAnimation.h"
#import "PKEase.h"
#import "PKEaseLinear.h"

static const NSString *kGZAnimationKeyPrefix = @"PKFadeAnimation";
static const CGFloat FPS = 30.0f;

@interface PKFadeAnimation ()
@property(nonatomic, weak) UIView *view;
@property(nonatomic) float duration;
@property(nonatomic) float from;
@property(nonatomic) float to;
@property(nonatomic, strong) id<PKEase> ease;
@property(nonatomic, strong) NSString *animationKey;
@property(nonatomic, strong) CAAnimation *animation;
@end

@implementation PKFadeAnimation {
}

- (id)initWithView: (UIView *)view duration: (float)duration from: (float)from to: (float)to {
    self = [self initWithView: view duration: duration from: from to: to ease: [[PKEaseLinear alloc] init]];
    return self;
}

- (id)initWithView: (UIView *)view duration: (float)duration from: (float)from to: (float)to ease: (id <PKEase>)ease {
    if(self = [super init])
    {
        NSAssert(view, @"view is nil!");
        NSAssert(ease, @"ease is nil! Use initWithView:duration:by:ease: instead");

        self.view = view;
        self.duration = duration;
        self.from = from;
        self.to = to;
        self.ease = ease;

        self.animationKey = [self createAnimationKey];
        self.animation = [self createAnimation];
    }

    return self;
}

- (void)dealloc {
    self.animationKey = nil;
    self.animation = nil;
    self.ease = nil;
}

- (void)execute {
    if([self completesImmediatly])
        [self fadeImmediatly];
    else
        [self startAnimation];
}

- (BOOL)completesImmediatly {
    return self.duration == 0.0f;
}

- (void)fadeImmediatly {
    self.view.alpha = self.to;
}

- (void)startAnimation {
    self.view.alpha = self.from;
    [self.view.layer addAnimation: self.animation forKey: self.animationKey];
}

- (void)animationDidStart:(CAAnimation *)theAnimation {
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    self.view.alpha = self.to;
    [self.view.layer removeAnimationForKey: self.animationKey];

    self.completeHandler();
}

- (NSString *)createAnimationKey {
    return [NSString stringWithFormat: @"%@_%f", kGZAnimationKeyPrefix, [[NSDate date] timeIntervalSince1970]];
}

- (CAAnimation *)createAnimation {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.delegate = self;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.repeatCount = 1;
    animation.duration = self.duration;
    animation.values = [self calculateValues];

    return animation;
}

- (NSMutableArray *)calculateValues {
    NSInteger frames = self.duration * FPS;
    float by = (self.to - self.from) / FPS;

    NSMutableArray* transforms = [NSMutableArray array];

    for(NSUInteger i = 0; i < frames; i++)
    {
        CGFloat value = [self.ease getValue: i startValue: self.from changeByValue: by duration: frames];

        [transforms addObject:[NSNumber numberWithFloat: value]];
    }

    return transforms;
}

@end