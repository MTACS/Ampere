#import <UIKit/UIKit.h>
#import "spawn.h"

#define BATTERY_IMAGE @"/Library/Application Support/Ampere/battery.png"

extern NSString *const kCAFilterDestOut;

static NSString *domain = @"com.mtac.amp";
static NSString *preferencesNotification = @"com.mtac.amp/preferences.changed";
static NSString *statusBarNotification = @"com.mtac.amp/statusbar.changed";
static BOOL enabled;
static BOOL overrideColors;
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

@interface NSUserDefaults (Ampere) // For preferences
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface _UIBatteryView : UIView
@property (retain, nonatomic) UIImageView *ampereImageView;
@property (retain, nonatomic) UILabel *percentageLabel;
@property (retain, nonatomic) CALayer *fillLayer;
@property (copy, nonatomic) UIColor *pinColor;
@property (nonatomic) CGFloat pinColorAlpha; 
@property (nonatomic) CGFloat bodyColorAlpha;
@property (nonatomic) BOOL saverModeActive;
@property (nonatomic) NSInteger chargingState;
- (id)_batteryFillColor;
- (id)_batteryTextColor;
- (void)updateAmpere;
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
- (id)applyUpdate:(id)arg0 toDisplayItem:(id)arg1;                                           
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
	return (self.state == 1) ? @"ϟ" : @"";
}
%end

%hook _UIBatteryView
%property (retain, nonatomic) UIImageView *ampereImageView; // Decided to use image view for easier customization, replace /Library/Application Support/Ampere/battery.png
- (id)_batteryFillColor {
	NSDictionary *textColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"textColor" inDomain:domain];
	if (textStyle == 2) {
		return [UIColor colorWithRed:[textColorDict[@"red"] floatValue] green:[textColorDict[@"green"] floatValue] blue:[textColorDict[@"blue"] floatValue] alpha:1.0];
	} else {
		return [UIColor systemBackgroundColor];
	}
	return [UIColor clearColor];
} 
- (id)bodyColor {
	return [UIColor clearColor];
}
- (id)pinColor {
	return [UIColor clearColor];
}
- (CGFloat)pinColorAlpha {
	return 0.0;
}
- (BOOL)_currentlyShowsPercentage {
	return YES;
}
- (id)initWithFrame:(CGRect)arg1 {
	self = %orig;
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAmpere) name:@"AmpereUpdate" object:nil];
	}
	return self;
}
- (BOOL)_shouldShowBolt {
	return NO;
}
- (void)setShowsPercentage:(BOOL)arg1 {
	%orig(NO);
}
- (void)setChargingState:(long long)arg1 {
	%orig;
    [self updateAmpere];
}
- (void)_willBeginAnimatingBoltToVisible:(BOOL)arg0 {
	%orig;
	[self updateAmpere];
}
%new
- (void)updateAmpere {
	if (!self.ampereImageView) self.ampereImageView = [[UIImageView alloc] initWithFrame:self.bounds];
	[self.ampereImageView setContentMode:UIViewContentModeScaleAspectFill];
	[self.ampereImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[self.ampereImageView setImage:[[UIImage imageWithContentsOfFile:BATTERY_IMAGE] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
	if (![self.ampereImageView isDescendantOfView:self]) {
		[self insertSubview:self.ampereImageView belowSubview:self.percentageLabel];
	}

	self.percentageLabel.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
	self.percentageLabel.textColor = [self _batteryFillColor];
	self.percentageLabel.layer.allowsGroupBlending = YES;
	self.percentageLabel.layer.allowsGroupOpacity = YES;
	self.percentageLabel.layer.compositingFilter = (textStyle == 1) ? kCAFilterDestOut : nil;
	[self.percentageLabel sizeToFit];
	if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
		self.percentageLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
	}
	
	self.pinColor = [UIColor clearColor];
	self.bodyColorAlpha = 0.0;
	self.pinColorAlpha = 0.0;
	self.fillLayer.hidden = YES;

	NSDictionary *standardColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"standardColor" inDomain:domain];
	NSDictionary *lowPowerColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"lowPowerColor" inDomain:domain];
	NSDictionary *chargingColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"chargingColor" inDomain:domain];
	UIColor *standardColor = overrideColors ? [UIColor colorWithRed:[standardColorDict[@"red"] floatValue] green:[standardColorDict[@"green"] floatValue] blue:[standardColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor labelColor];
	UIColor *lowPowerColor = overrideColors ? [UIColor colorWithRed:[lowPowerColorDict[@"red"] floatValue] green:[lowPowerColorDict[@"green"] floatValue] blue:[lowPowerColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemYellowColor];
	UIColor *chargingColor = overrideColors ? [UIColor colorWithRed:[chargingColorDict[@"red"] floatValue] green:[chargingColorDict[@"green"] floatValue] blue:[chargingColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemGreenColor];

	[self.ampereImageView setTintColor:standardColor];

	if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
		[self.ampereImageView setTintColor:lowPowerColor];
	} else {
		if (self.chargingState == 1) {
			[self.ampereImageView setTintColor:chargingColor];
		}
	}
}
%end

%hook SpringBoard
- (void)_batterySaverModeChanged:(int)arg1  {
	%orig;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AmpereUpdate" object:nil];
}
%end
%end

static void reloadStatusBar(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AmpereUpdate" object:nil];
}

static void loadPreferences(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSNumber *enabledValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain];
	enabled = (enabledValue) ? [enabledValue boolValue] : NO;
	NSNumber *overrideColorsValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColors" inDomain:domain];
	overrideColors = (overrideColorsValue) ? [overrideColorsValue boolValue] : NO;
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