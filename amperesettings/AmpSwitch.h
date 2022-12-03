#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

#define LIGHT_TINT [UIColor colorWithRed: 0.20 green: 0.60 blue: 0.86 alpha: 1.00]
#define DARK_TINT [UIColor colorWithRed: 0.36 green: 0.68 blue: 0.89 alpha: 1.00]

typedef enum {
    AmpSwitchStyleLight,
    AmpSwitchStyleDark,
    AmpSwitchStyleDefault
} AmpSwitchStyle;

typedef enum {
    AmpSwitchStateOn,
    AmpSwitchStateOff
} AmpSwitchState;

typedef enum {
    AmpSwitchSizeBig,
    AmpSwitchSizeNormal,
    AmpSwitchSizeSmall
} AmpSwitchSize;

@protocol AmpSwitchDelegate <NSObject>
- (void)switchStateChanged:(AmpSwitchState)currentState;
@end

@interface AmpSwitch : UIControl
@property (nonatomic, assign) id<AmpSwitchDelegate> delegate;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, strong) UIColor *thumbOnTintColor;
@property (nonatomic, strong) UIColor *thumbOffTintColor;
@property (nonatomic, strong) UIColor *trackOnTintColor;
@property (nonatomic, strong) UIColor *trackOffTintColor;
@property (nonatomic, strong) UIColor *thumbDisabledTintColor;
@property (nonatomic, strong) UIColor *trackDisabledTintColor;
@property (nonatomic, strong) UIButton *switchThumb;
@property (nonatomic, strong) UIView *track;
- (id)init;
- (id)initWithSize:(AmpSwitchSize)size state:(AmpSwitchState)state;
- (id)initWithSize:(AmpSwitchSize)size style:(AmpSwitchStyle)style state:(AmpSwitchState)state;
- (BOOL)getSwitchState;
- (void)setOn:(BOOL)on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)setThumbState:(BOOL)state animated:(BOOL)animated;
@end