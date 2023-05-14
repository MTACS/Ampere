#import <UIKit/UIKit.h>
#import "spawn.h"
#import "RemoteLog.h"
#include <objc/runtime.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_16_0
#define kCFCoreFoundationVersionNumber_iOS_16_0 1946.10
#endif
#define kSLSystemVersioniOS16 kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_16_0

extern NSString *const kCAFilterDestOut;

static NSString *domain = @"com.mtac.amp";
static NSString *preferencesNotification = @"com.mtac.amp/preferences.changed";
static NSString *statusBarNotification = @"com.mtac.amp/statusbar.changed";
static BOOL enabled;
static BOOL showBolt;
static BOOL useGesture;
static BOOL overrideColorStandard;
static BOOL overrideColorCharging;
static BOOL overrideColorLowPower;
static BOOL overrideColorCritical;
static NSInteger textStyle;
static NSInteger fontSize;
static NSInteger batterySizing;

@interface CALayer (Ampere)
@property (nonatomic, retain) NSString *compositingFilter;
@property (nonatomic, assign) BOOL allowsGroupOpacity;
@property (nonatomic, assign) BOOL allowsGroupBlending;
@property (copy) NSString *cornerCurve;
@end

@interface _CDBatterySaver : NSObject
+ (id)batterySaver;
- (NSInteger)getPowerMode;
- (BOOL)setPowerMode:(NSInteger)arg0 error:(id)arg1;
@end

@interface _PMLowPowerMode : NSObject
+ (id)sharedInstance;
- (NSInteger)getPowerMode;
- (void)setPowerMode:(NSInteger)arg0 fromSource:(id)arg1;
- (void)setPowerMode:(NSInteger)arg0 fromSource:(id)arg1 withCompletion:(id)arg2;
@end

@interface NSUserDefaults (Ampere)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface _UIBatteryView : UIView
@property (readonly, nonatomic, getter=isLowBattery) BOOL lowBattery;
@property (retain, nonatomic) UIImageView *ampereImageView;
@property (retain, nonatomic) UILabel *percentageLabel;
@property (retain, nonatomic) CALayer *fillLayer;
@property (retain, nonatomic) CALayer *pinLayer; 
@property (copy, nonatomic) UIColor *pinColor;
@property (nonatomic) CGFloat pinColorAlpha; 
@property (nonatomic) CGFloat bodyColorAlpha;
@property (nonatomic) CGFloat chargePercent;
@property (nonatomic) BOOL saverModeActive;
@property (nonatomic) NSInteger chargingState;
@property (nonatomic) NSInteger iconSize;
- (CGRect)_bodyRectForTraitCollection:(id)arg0;
- (id)_batteryFillColor;
- (id)_batteryTextColor;
- (void)_updateBatteryFillColor;
- (void)_updatePercentage;
- (id)initWithSizeCategory:(NSInteger)arg0;
- (UIColor *)ampereFillColor;
@end

@interface BCUIRowView : UIView
@property (nonatomic, strong) _UIBatteryView *ampereBatteryView;
@property (nonatomic) NSInteger percentCharge;
@end

@interface BCUIBatteryView : _UIBatteryView
@end

@interface _UIStaticBatteryView : _UIBatteryView
- (void)setShowsPercentage:(BOOL)arg0;
@end

@interface UIStatusBarItem : NSObject
@end

@interface _UIStatusBarDisplayItem : NSObject
@property (nonatomic, getter=isEnabled) BOOL enabled;
@end

@interface _UIStatusBarStringView : UIView
- (void)setText:(id)arg0;
@end

@interface _UIStatusBarBatteryItem : UIStatusBarItem
@property (retain, nonatomic) _UIStatusBarStringView *percentView;
+ (id)staticIconDisplayIdentifier;
+ (id)iconDisplayIdentifier;
- (void)toggleLowPower:(id)sender;
@end

@interface _UIStatusBarDataBatteryEntry : NSObject
@property (nonatomic) NSInteger state;
@end