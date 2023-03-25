#import <UIKit/UIKit.h>
#import "spawn.h"

#define ROOT_PATH_NS(path)([[NSFileManager defaultManager] fileExistsAtPath:path] ? path : [@"/var/jb" stringByAppendingPathComponent:path])
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

%group Ampere
%hook _UIStatusBarBatteryItem
- (_UIBatteryView *)batteryView {
	_UIBatteryView *batteryView = %orig;
	if (useGesture) {
		[batteryView setUserInteractionEnabled:YES];

		UITapGestureRecognizer *toggleLowPower = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleLowPower:)];
		toggleLowPower.numberOfTapsRequired = 1;
		if (batteryView.gestureRecognizers.count == 0) {
			[batteryView addGestureRecognizer:toggleLowPower];
		}
	}
	return %orig;
}
%new
- (void)toggleLowPower:(id)sender {
	if (%c(_PMLowPowerMode)) {
		_PMLowPowerMode *lowPowerMode = [%c(_PMLowPowerMode) sharedInstance];
		BOOL active = [lowPowerMode getPowerMode] == 1;
		[lowPowerMode setPowerMode:!active fromSource:@"SpringBoard"];
	} else {
		long long state = [[%c(_CDBatterySaver) batterySaver] getPowerMode];
		if (state == 0) {
			[[%c(_CDBatterySaver) batterySaver] setPowerMode:1 error:nil];
		} 
		if (state == 1) {
			[[%c(_CDBatterySaver) batterySaver] setPowerMode:0 error:nil];
		}
	}
}
%end

%hook _UIBatteryView
- (id)initWithFrame:(CGRect)arg1 {
	self = %orig;
	if (self) {
		// Notifications for automatic prefs updates
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateBatteryFillColor) name:@"AmpereUpdate" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updatePercentage) name:@"AmpereUpdate" object:nil];
	}
	return self;
}
- (id)_batteryTextColor {
	if (textStyle == 0) {
		if (self.saverModeActive) {
			return [UIColor blackColor];
		}
	} else if (textStyle == 2) { // Use custom percentage text color
		NSDictionary *textColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"textColorDict" inDomain:domain];
		UIColor *textColor = [UIColor colorWithRed:[textColorDict[@"red"] floatValue] green:[textColorDict[@"green"] floatValue] blue:[textColorDict[@"blue"] floatValue] alpha:1.0];
		return textColor;
	}
	return %orig;
}
- (UIColor *)_batteryFillColor { // Return default or custom fill colors based on charging state
	NSDictionary *standardColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorStandardDict" inDomain:domain];
	NSDictionary *lowPowerColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorLowPowerDict" inDomain:domain];
	NSDictionary *chargingColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorChargingDict" inDomain:domain];
	NSDictionary *criticalColorDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorCriticalDict" inDomain:domain];
	UIColor *standardColor = overrideColorStandard ? [UIColor colorWithRed:[standardColorDict[@"red"] floatValue] green:[standardColorDict[@"green"] floatValue] blue:[standardColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor labelColor];
	UIColor *lowPowerColor = overrideColorLowPower ? [UIColor colorWithRed:[lowPowerColorDict[@"red"] floatValue] green:[lowPowerColorDict[@"green"] floatValue] blue:[lowPowerColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemYellowColor];
	UIColor *chargingColor = overrideColorCharging ? [UIColor colorWithRed:[chargingColorDict[@"red"] floatValue] green:[chargingColorDict[@"green"] floatValue] blue:[chargingColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemGreenColor];
	UIColor *criticalColor = overrideColorCritical ? [UIColor colorWithRed:[criticalColorDict[@"red"] floatValue] green:[criticalColorDict[@"green"] floatValue] blue:[criticalColorDict[@"blue"] floatValue] alpha:1.0] : [UIColor systemRedColor];

	if (!self.saverModeActive) { // Normal use
		if (self.chargingState == 1) { // Charging
			return chargingColor; 
		} else if (self.lowBattery) {
			return criticalColor;
		} else return standardColor; // Color of normal use (not charging & not in Low Power mode)
	} else { // Low Power, overrides custom charging color
		return lowPowerColor;
	}
	return %orig;
}
%end

%hook _UIStatusBarDataBatteryEntry
- (NSString *)detailString {
	return @""; // Return empty string to keep automatic sizing
}
%end
%end

%group XVI
%hook _UIStaticBatteryView
- (void)setShowsPercentage:(BOOL)arg0 {
	%orig(YES);
}
%end

%hook _UIBatteryView
- (BOOL)_batteryTextIsCutout {
	if (textStyle == 1) {
		return YES;
	}
	return %orig;
}
%end
%end

%group XV
%hook _UIBatteryView
- (void)setSaverModeActive:(BOOL)arg1 {
	%orig;
	[self _updatePercentage];
}
- (UIColor *)pinColor {
	return (self.chargePercent > 0.97) ? [self _batteryFillColor] : %orig; // Set pin color to fill color, but only when charge exceeds frame of regular battery body
}
+ (id)_pinBezierPathForSize:(struct CGSize )arg0 complex:(BOOL)arg1 {
	UIBezierPath *path = %orig;
	if (batterySizing == 1) {
		[path applyTransform:CGAffineTransformMakeTranslation(1, 0)]; // Shift pin 1 px, done because setting line interspace width to fill body adds border
	}
	return path;
}
- (void)_updateFillLayer {
	%orig;
	[self.fillLayer setCornerRadius:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 4.0 : 3.5]; // Set fill corner radius whenever layer updates
}
- (void)_updatePercentage {
	%orig;
	self.percentageLabel.font = [UIFont systemFontOfSize:((self.chargingState == 1 || self.chargePercent == 1.0) && fontSize > 10) ? 10 : fontSize weight:((batterySizing == 1) ? UIFontWeightHeavy : UIFontWeightBold)]; // Set custom percentage font size
	if (showBolt && self.chargingState == 1) { // Show bolt next to percentage label text
		NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
		[attachment setBounds:CGRectMake(0, 0, roundf(self.percentageLabel.font.capHeight * 0.6), roundf(self.percentageLabel.font.capHeight))];
		[attachment setImage:[[UIImage systemImageNamed:@"bolt.fill"] imageWithTintColor:(self.saverModeActive) ? [UIColor blackColor] : [self _batteryTextColor]]];
	
		NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:self.percentageLabel.text];
		[atr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];		
		self.percentageLabel.attributedText = atr;
	}
	self.percentageLabel.layer.allowsGroupBlending = YES;
	self.percentageLabel.layer.allowsGroupOpacity = YES;
	self.percentageLabel.layer.compositingFilter = (textStyle == 1) || (textStyle == 0 && (self.chargingState != 1) && !self.saverModeActive) ? kCAFilterDestOut : nil; // Enable cutout effect on text when in transparent mode or default (when not charging)

	[self.percentageLabel sizeToFit];
	if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) { // Support RTL languages
		self.percentageLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
	}
}
- (CGFloat)_outsideCornerRadiusForTraitCollection:(id)arg0 {
	return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 4.0 : 3.5; // Slightly adjust corner radius for expanded height
}
- (CGFloat)bodyColorAlpha {
	return 1.0; // Overrides default fill color alpha (normally 0.4)
}
- (CAShapeLayer *)bodyShapeLayer {
	CAShapeLayer *bodyLayer = %orig;
	bodyLayer.fillColor = [[UIColor labelColor] colorWithAlphaComponent:0.4].CGColor; // Fill exisiting battery view completely
	return bodyLayer;
}
- (CALayer *)fillLayer {
	CALayer *fill = %orig;
	fill.maskedCorners = (self.chargePercent > 0.9) ? (kCALayerMaxXMaxYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner) : (kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner); // Rounded corners always on leading edge, flat on trailing until above 92% to match stock radius
	fill.bounds = CGRectMake(fill.bounds.origin.x, fill.bounds.origin.y - ((batterySizing == 1) ? 1 : 0), fill.bounds.size.width - 1, self.bounds.size.height + ((batterySizing == 1) ? 2 : 0));
	return fill;
}
- (CGRect)_bodyRectForTraitCollection:(id)arg0 {
	CGRect bodyRect = %orig;
	return CGRectMake(bodyRect.origin.x, bodyRect.origin.y - ((batterySizing == 1) ? 1 : 0), bodyRect.size.width - 1, bodyRect.size.height + ((batterySizing == 1) ? 2 : 0)); // Resize view height to better replicate iOS 16
}
- (CGFloat)_lineWidthAndInterspaceForTraitCollection:(id)arg0 {
	return 0; // Disable space between fill layer and border of body layer
}
- (BOOL)_shouldShowBolt {
	return NO; // Disable interior bolt when charging
}
- (BOOL)_currentlyShowsPercentage {
	return YES; // Always display battery percentage label
}
%end

%hook _UIStatusBarBatteryItem
+ (id)staticIconDisplayIdentifier {
	return [self iconDisplayIdentifier]; // Override static identifier, used in iPhone Control Center & everywhere on iPad
}
%end
%end

static void reloadStatusBar(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AmpereUpdate" object:nil]; // Post local update notification
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
	NSNumber *overrideColorCriticalValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"overrideColorCritical" inDomain:domain];
	overrideColorCritical = (overrideColorCriticalValue) ? [overrideColorCriticalValue boolValue] : NO;
	NSNumber *useGestureValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"useGesture" inDomain:domain];
	useGesture = (useGestureValue) ? [useGestureValue boolValue] : NO;

	NSNumber *textStyleValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain];
	textStyle = (textStyleValue) ? [textStyleValue integerValue] : 0;
	NSNumber *fontSizeValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"fontSize" inDomain:domain];
	fontSize = (fontSizeValue) ? [fontSizeValue integerValue] : 8;
	NSNumber *batterySizingValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"batterySizing" inDomain:domain];
	batterySizing = (batterySizingValue) ? [batterySizingValue integerValue] : 1;
}

%ctor {
	loadPreferences(NULL, NULL, NULL, NULL, NULL); // Load prefs
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPreferences, (CFStringRef)preferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce); // Preferences changed
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, reloadStatusBar, (CFStringRef)statusBarNotification, NULL, CFNotificationSuspensionBehaviorCoalesce); // Update status bar
	if (enabled) {
		%init(Ampere);
		if (!(kSLSystemVersioniOS16)) {
			%init(XV);
		} else {
			%init(XVI);
		}
	}
}