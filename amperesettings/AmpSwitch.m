#import "AmpSwitch.h"

@interface AmpSwitch ()
@property (nonatomic) CGFloat trackThickness;
@property (nonatomic) CGFloat thumbSize;
@end

@implementation AmpSwitch {
    float thumbOnPosition;
    float thumbOffPosition;
    AmpSwitchStyle thumbStyle;
}
- (id)init {
    self = [self initWithSize:AmpSwitchSizeNormal style:AmpSwitchStyleDefault state:AmpSwitchStateOff];
    return self;
}
- (id)initWithSize:(AmpSwitchSize)size state:(AmpSwitchState)state {
    self.thumbOnTintColor  = [UIColor colorWithRed:52./255. green:109./255. blue:241./255. alpha:1.0];
    self.thumbOffTintColor = [UIColor colorWithRed:249./255. green:249./255. blue:249./255. alpha:1.0];
    self.trackOnTintColor = [UIColor colorWithRed:143./255. green:179./255. blue:247./255. alpha:1.0];
    self.trackOffTintColor = [UIColor colorWithRed:193./255. green:193./255. blue:193./255. alpha:1.0];
    self.thumbDisabledTintColor = [UIColor colorWithRed:174./255. green:174./255. blue:174./255. alpha:1.0];
    self.trackDisabledTintColor = [UIColor colorWithRed:203./255. green:203./255. blue:203./255. alpha:1.0];
    self.isEnabled = YES;
    
    CGRect frame;
    CGRect trackFrame = CGRectZero;
    CGRect thumbFrame = CGRectZero;
    switch (size) {
        case AmpSwitchSizeBig:
        frame = CGRectMake(0, 0, 50, 40);
        self.trackThickness = 23.0;
        self.thumbSize = 31.0;
        break;
        
        case AmpSwitchSizeNormal:
        frame = CGRectMake(0, 0, 40, 30);
        self.trackThickness = 17.0;
        self.thumbSize = 24.0;
        break;
        
        case AmpSwitchSizeSmall:
        frame = CGRectMake(0, 0, 30, 25);
        self.trackThickness = 13.0;
        self.thumbSize = 18.0;
        break;
        
        default:
        frame = CGRectMake(0, 0, 40, 30);
        self.trackThickness = 13.0;
        self.thumbSize = 20.0;
        break;
    }
    
    trackFrame.size.height = self.trackThickness;
    trackFrame.size.width = frame.size.width;
    trackFrame.origin.x = 0.0;
    trackFrame.origin.y = (frame.size.height-trackFrame.size.height)/2;
    thumbFrame.size.height = self.thumbSize;
    thumbFrame.size.width = thumbFrame.size.height;
    thumbFrame.origin.x = 0.0;
    thumbFrame.origin.y = (frame.size.height-thumbFrame.size.height)/2;
    
    self = [super initWithFrame:frame];
    
    self.track = [[UIView alloc] initWithFrame:trackFrame];
    self.track.backgroundColor = [UIColor grayColor];
    self.track.layer.cornerRadius = MIN(self.track.frame.size.height, self.track.frame.size.width)/2;
    [self addSubview:self.track];
    
    self.switchThumb = [[UIButton alloc] initWithFrame:thumbFrame];
    self.switchThumb.backgroundColor = [UIColor whiteColor];
    self.switchThumb.layer.cornerRadius = self.switchThumb.frame.size.height/2;
    self.switchThumb.layer.shadowOpacity = 0.5;
    self.switchThumb.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.switchThumb.layer.shadowColor = [UIColor blackColor].CGColor;
    self.switchThumb.layer.shadowRadius = 2.0f;
    [self.switchThumb addTarget:self action:@selector(onTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
    [self.switchThumb addTarget:self action:@selector(onTouchUpOutsideOrCanceled:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
    [self.switchThumb addTarget:self action:@selector(switchThumbTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchThumb addTarget:self action:@selector(onTouchDragInside:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [self.switchThumb addTarget:self action:@selector(onTouchUpOutsideOrCanceled:withEvent:) forControlEvents:UIControlEventTouchCancel];
    
    [self addSubview:self.switchThumb];
    
    thumbOnPosition = self.frame.size.width - self.switchThumb.frame.size.width;
    thumbOffPosition = self.switchThumb.frame.origin.x;
    
    switch (state) {
        case AmpSwitchStateOn:
        self.isOn = YES;
        self.switchThumb.backgroundColor = self.thumbOnTintColor;
        CGRect thumbFrame = self.switchThumb.frame;
        thumbFrame.origin.x = thumbOnPosition;
        self.switchThumb.frame = thumbFrame;
        break;
        
        case AmpSwitchStateOff:
        self.isOn = NO;
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        break;
        
        default:
        self.isOn = NO;
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        break;
    }
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchAreaTapped:)];
    [self addGestureRecognizer:singleTap];
    return self;
}
- (id)initWithSize:(AmpSwitchSize)size style:(AmpSwitchStyle)style state:(AmpSwitchState)state {
    self = [self initWithSize:size state:state];
    if (self) {
        self.thumbOnTintColor = LIGHT_TINT;
        self.thumbOffTintColor = [UIColor systemGray3Color];
        self.trackOnTintColor = DARK_TINT;
        self.trackOffTintColor = [UIColor systemGrayColor];
        self.thumbDisabledTintColor = [UIColor systemGray2Color];
        self.trackDisabledTintColor = [UIColor systemGray2Color];
    }
    return self;
}
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (self.isOn == YES) {
        self.switchThumb.backgroundColor = self.thumbOnTintColor;
        self.track.backgroundColor = self.trackOnTintColor;
    } else {
        self.switchThumb.backgroundColor = self.thumbOffTintColor;
        self.track.backgroundColor = self.trackOffTintColor;
        [self setThumbState:NO animated:NO];
    }
    if (self.isEnabled == NO) {
        self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
        self.track.backgroundColor = self.trackDisabledTintColor;
    }
}
- (BOOL)getSwitchState {
  return self.isOn;
}
- (void)setOn:(BOOL)on {
  [self setOn:on animated:NO];
}
- (void)setOn:(BOOL)on animated:(BOOL)animated {
    [self setThumbState:on animated:animated];
}
- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
  
    [UIView animateWithDuration:0.1 animations:^{
        if (enabled == YES) {
            if (self.isOn == YES) {
                self.switchThumb.backgroundColor = self.thumbOnTintColor;
                self.track.backgroundColor = self.trackOnTintColor;
            } else {
                self.switchThumb.backgroundColor = self.thumbOffTintColor;
                self.track.backgroundColor = self.trackOffTintColor;
            }
            self.isEnabled = YES;
        } else {
            self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
            self.track.backgroundColor = self.trackDisabledTintColor;
            self.isEnabled = NO;
        }
    }];
}
- (void)switchAreaTapped:(UITapGestureRecognizer *)recognizer {
    if ([self.delegate respondsToSelector:@selector(switchStateChanged:)]) {
        if (self.isOn == YES) {
            [self.delegate switchStateChanged:AmpSwitchStateOff];
        } else{
            [self.delegate switchStateChanged:AmpSwitchStateOn];
        }
    }
    [self changeThumbState];
}
- (void)changeThumbState {
    [self setThumbState:!self.isOn animated:YES];
}
- (void)setThumbState:(BOOL)state animated:(BOOL)animated {
    if (state) {
        if (animated) {
            [UIView animateWithDuration:0.15f delay:0.05f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect thumbFrame = self.switchThumb.frame;
                thumbFrame.origin.x = thumbOnPosition + 3.0;
                self.switchThumb.frame = thumbFrame;
                if (self.isEnabled == YES) {
                    self.switchThumb.backgroundColor = self.thumbOnTintColor;
                    self.track.backgroundColor = self.trackOnTintColor;
                } else {
                    self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
                    self.track.backgroundColor = self.trackDisabledTintColor;
                }
                self.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                if (self.isOn == NO) {
                    self.isOn = YES;
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }
                self.isOn = YES;
                [UIView animateWithDuration:0.15f animations:^{
                    CGRect thumbFrame = self.switchThumb.frame;
                    thumbFrame.origin.x = thumbOnPosition;
                    self.switchThumb.frame = thumbFrame;
                } completion:^(BOOL finished) {
                    self.userInteractionEnabled = YES;
                }];
            }];
        } else {
            CGRect thumbFrame = self.switchThumb.frame;
            thumbFrame.origin.x = thumbOnPosition;
            self.switchThumb.frame = thumbFrame;
            if (self.isEnabled == YES) {
                self.switchThumb.backgroundColor = self.thumbOnTintColor;
                self.track.backgroundColor = self.trackOnTintColor;
            } else {
                self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
                self.track.backgroundColor = self.trackDisabledTintColor;
            }
        
            if (self.isOn == NO) {
                self.isOn = YES;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
            self.isOn = YES;
        }
    } else {
        if (animated) {
            [UIView animateWithDuration:0.15f delay:0.05f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect thumbFrame = self.switchThumb.frame;
                thumbFrame.origin.x = thumbOffPosition - 3.0;
                self.switchThumb.frame = thumbFrame;
                if (self.isEnabled == YES) {
                    self.switchThumb.backgroundColor = self.thumbOffTintColor;
                    self.track.backgroundColor = self.trackOffTintColor;
                } else {
                    self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
                    self.track.backgroundColor = self.trackDisabledTintColor;
                }
                self.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                if (self.isOn == YES) {
                    self.isOn = NO;
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }
                self.isOn = NO;
                [UIView animateWithDuration:0.15f animations:^{
                    CGRect thumbFrame = self.switchThumb.frame;
                    thumbFrame.origin.x = thumbOffPosition;
                    self.switchThumb.frame = thumbFrame;
                } completion:^(BOOL finished) {
                    self.userInteractionEnabled = YES;
                }];
            }];
        } else {
            CGRect thumbFrame = self.switchThumb.frame;
            thumbFrame.origin.x = thumbOffPosition;
            self.switchThumb.frame = thumbFrame;
            if (self.isEnabled == YES) {
                self.switchThumb.backgroundColor = self.thumbOffTintColor;
                self.track.backgroundColor = self.trackOffTintColor;
            } else {
                self.switchThumb.backgroundColor = self.thumbDisabledTintColor;
                self.track.backgroundColor = self.trackDisabledTintColor;
            }
        
            if (self.isOn == YES) {
                self.isOn = NO;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
            self.isOn = NO;
        }
    }
}
- (void)onTouchDown:(UIButton *)button withEvent:(UIEvent *)event {

}
- (void)switchThumbTapped: (id)sender {
    if ([self.delegate respondsToSelector:@selector(switchStateChanged:)]) {
        if (self.isOn == YES) {
            [self.delegate switchStateChanged:AmpSwitchStateOff];
        } else{
            [self.delegate switchStateChanged:AmpSwitchStateOn];
        }
    }
    [self changeThumbState];
}
- (void)onTouchUpOutsideOrCanceled:(UIButton *)button withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint previous = [touch previousLocationInView:button];
    CGPoint position = [touch locationInView:button];
    float dX = position.x - previous.x;
    float origin = button.frame.origin.x + dX;
 
    if (origin > (self.frame.size.width - self.switchThumb.frame.size.width) / 2) {
        [self setThumbState:YES animated:YES];
    } else {
        [self setThumbState:NO animated:YES];
    }
}
- (void)onTouchDragInside:(UIButton *)button withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint previous = [touch previousLocationInView:button];
    CGPoint position = [touch locationInView:button];
    float dX = position.x - previous.x;
    
    CGRect thumbFrame = button.frame;
    
    thumbFrame.origin.x += dX;
    thumbFrame.origin.x = MIN(thumbFrame.origin.x, thumbOnPosition);
    thumbFrame.origin.x = MAX(thumbFrame.origin.x, thumbOffPosition);
    
    if (thumbFrame.origin.x != button.frame.origin.x) {
        button.frame = thumbFrame;
    }
}
@end