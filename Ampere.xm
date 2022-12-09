#import <UIKit/UIKit.h>
#import "spawn.h"

#define BATTERY_IMAGE @"/Library/Application Support/Ampere/battery.png"

extern NSString *const kCAFilterDestOut;

static NSString *domain = @"com.mtac.amp";
static NSString *preferencesNotification = @"com.mtac.amp/preferences.changed";
static NSString *statusBarNotification = @"com.mtac.amp/statusbar.changed";
static BOOL enabled;
static BOOL showBolt;
static BOOL overrideColorStandard;
static BOOL overrideColorCharging;
static BOOL overrideColorLowPower;
static NSInteger textStyle;
static NSInteger fontSize;

@interface CALayer (Ampere)
@property (nonatomic, retain) NSString *compositingFilter;
@property (nonatomic, assign) BOOL allowsGroupOpacity;
@property (nonatomic, assign) BOOL allowsGroupBlending;
@end

@interface _CDBatterySaver : NSObject
+ (id)batterySaver;
- (NSInteger)getPowerMode;
@end

@interface NSUserDefaults (Ampere)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface _UIBatteryView : UIView
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
@end

@interface _UIStatusBarDataBatteryEntry : NSObject
@property (nonatomic) NSInteger state;
@end

@interface SBApplication: NSObject
@property (nonatomic, readonly) NSString *bundleIdentifier;
@end

@interface SpringBoard: NSObject
+ (id)sharedApplication;
- (SBApplication *)_accessibilityFrontMostApplication;
@end

%group Ampere
%hook _UIStatusBarDataBatteryEntry
- (NSString *)detailString {
	return showBolt ? @"" : %orig;
}
%end

%hook _UIStatusBarBatteryItem
+ (id)staticIconDisplayIdentifier {
	return [self iconDisplayIdentifier];
}
%end

%hook _UIBatteryView
- (id)initWithFrame:(CGRect)arg1 {
	self = %orig;
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateBatteryFillColor) name:@"AmpereUpdate" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updatePercentage) name:@"AmpereUpdate" object:nil];
	}
	return self;
}
- (CAShapeLayer *)bodyShapeLayer {
	CAShapeLayer *bodyLayer = %orig;
	bodyLayer.fillColor = [[UIColor labelColor] colorWithAlphaComponent:0.4].CGColor;
	return bodyLayer;
}
- (CALayer *)fillLayer {
	CALayer *fill = %orig;
	fill.maskedCorners = (self.chargePercent > 0.92) ? (kCALayerMaxXMaxYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner) : (kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner);
	fill.bounds = CGRectMake(fill.bounds.origin.x, fill.bounds.origin.y - 1, fill.bounds.size.width, self.bounds.size.height + 2);
	return fill;
}
- (CGRect)_bodyRectForTraitCollection:(id)arg0 {
	CGRect bodyRect = %orig;
	return CGRectMake(bodyRect.origin.x, bodyRect.origin.y - 1, bodyRect.size.width, bodyRect.size.height + 2);
}
- (CGFloat)_lineWidthAndInterspaceForTraitCollection:(id)arg0 {
	return 0;
}
- (BOOL)_shouldShowBolt {
	return NO;
}
- (BOOL)_currentlyShowsPercentage {
	return YES;
}
- (void)_updatePercentage {
	%orig;
	self.percentageLabel.font = [UIFont systemFontOfSize:((self.chargingState == 1 || self.chargePercent == 1.0) && fontSize > 10) ? 10 : fontSize weight:UIFontWeightBold];
	if (showBolt && self.chargingState == 1) {
		NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
		[attachment setBounds:CGRectMake(0, 0, roundf(self.percentageLabel.font.capHeight * 0.5), roundf(self.percentageLabel.font.capHeight))];
		[attachment setImage:[[UIImage systemImageNamed:@"bolt.fill"] imageWithTintColor:[self _batteryTextColor]]];
	
		NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:self.percentageLabel.text];
		[atr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];		
		self.percentageLabel.attributedText = atr;
	}
	self.percentageLabel.layer.allowsGroupBlending = YES;
	self.percentageLabel.layer.allowsGroupOpacity = YES;
	self.percentageLabel.layer.compositingFilter = (textStyle == 1) || (textStyle == 0 && self.chargingState != 1) ? kCAFilterDestOut : nil;

	[self.percentageLabel sizeToFit];
	if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
		self.percentageLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
	}
}
- (CGFloat)_outsideCornerRadiusForTraitCollection:(id)arg0 {
	return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 4.0 : 3.5;
}
- (CGFloat)bodyColorAlpha {
	return 1.0;
}
- (id)_batteryTextColor {
	if (textStyle == 2) {
		NSDictionary *textColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"textColorDict" inDomain:domain];
		UIColor *textColor = [UIColor colorWithRed:[textColorDict[@"red"] floatValue] green:[textColorDict[@"green"] floatValue] blue:[textColorDict[@"blue"] floatValue] alpha:1.0];
		return textColor;
	}
	return %orig;
}
- (UIColor *)_batteryFillColor {
	NSDictionary *standardColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorStandardDict" inDomain:domain];
	NSDictionary *lowPowerColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorLowPowerDict" inDomain:domain];
	NSDictionary *chargingColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorChargingDict" inDomain:domain];
	UIColor *standardColor = overrideColorStandard ? [UIColor colorWithRed:[standardColorDict[@"red"] floatValue] green:[standardColorDict[@"green"] floatValue] blue:[standardColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor labelColor];
	UIColor *lowPowerColor = overrideColorLowPower ? [UIColor colorWithRed:[lowPowerColorDict[@"red"] floatValue] green:[lowPowerColorDict[@"green"] floatValue] blue:[lowPowerColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemYellowColor];
	UIColor *chargingColor = overrideColorCharging ? [UIColor colorWithRed:[chargingColorDict[@"red"] floatValue] green:[chargingColorDict[@"green"] floatValue] blue:[chargingColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemGreenColor];

	if (!self.saverModeActive) {
		if (self.chargingState == 1) {
			return chargingColor;
		} return standardColor;
	} else {
		return lowPowerColor;
	}
	return %orig;
}
- (UIColor *)pinColor {
	return [self _batteryFillColor];
}
+ (id)_pinBezierPathForSize:(struct CGSize )arg0 complex:(BOOL)arg1 {
	UIBezierPath *path = %orig;
	[path applyTransform:CGAffineTransformMakeTranslation(1, 0)];
	return path;
}
- (void)_updateFillLayer {
	%orig;
	[self.fillLayer setCornerRadius:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 4.0 : 3.5];
}
%end
%end

static void reloadStatusBar(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AmpereUpdate" object:nil];
}

static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain];
	enabled = (enabledValue) ? [enabledValue boolValue] : NO;
	NSNumber *showBoltValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"showBolt" inDomain: domain];
	showBolt = (showBoltValue) ? [showBoltValue boolValue] : YES;
	NSNumber *overrideColorStandardValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorStandard" inDomain:domain];
	overrideColorStandard = (overrideColorStandardValue) ? [overrideColorStandardValue boolValue] : NO;
	NSNumber *overrideColorChargingValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorCharging" inDomain:domain];
	overrideColorCharging = (overrideColorChargingValue) ? [overrideColorChargingValue boolValue] : NO;
	NSNumber *overrideColorLowPowerValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorLowPower" inDomain:domain];
	overrideColorLowPower = (overrideColorLowPowerValue) ? [overrideColorLowPowerValue boolValue] : NO;

	NSNumber *textStyleValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain];
	textStyle = (textStyleValue) ? [textStyleValue integerValue] : 1;
	NSNumber *fontSizeValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"fontSize" inDomain:domain];
	fontSize = (fontSizeValue) ? [fontSizeValue integerValue] : 8;
}

%ctor {
	loadPreferences(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, reloadStatusBar, (CFStringRef)statusBarNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	if (enabled) {
		%init(Ampere);
	}
}