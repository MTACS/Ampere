#import "Ampere.h"

NSString *batteryCharging() {
	UIDevice *device = [UIDevice currentDevice];
	device.batteryMonitoringEnabled = YES;
	switch ([device batteryState]) {
		case UIDeviceBatteryStateCharging:
			return @"Yes";
		case UIDeviceBatteryStateFull:
		case UIDeviceBatteryStateUnplugged:
		case UIDeviceBatteryStateUnknown:
		default:
			return @"No";
	}
}

NSString *celsiusTemperature() {
	io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
	if (powerSource) {
		CFMutableDictionaryRef batteryDictionaryRef = NULL;
		if (IORegistryEntryCreateCFProperties(powerSource, &batteryDictionaryRef, 0, 0) == KERN_SUCCESS) {
			float temperature = -1;
			CFNumberRef temperatureRef = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("Temperature"), kCFAllocatorDefault, 0);
			CFNumberGetValue(temperatureRef, kCFNumberFloatType, &temperature);
			CFRelease(temperatureRef);
			return [NSString stringWithFormat:@"%.1f°C", temperature / 100];
		}
	}
	return @"--°C";
}

NSString *fahrenheitTemperature() {
	NSString *celsiusMethod = celsiusTemperature();
	NSString *celsius = [celsiusMethod substringToIndex:celsiusMethod.length - 2];
	if ([celsius isEqualToString:@"--"])
		return [celsius stringByAppendingString:@"°F"];
	return [NSString stringWithFormat:@"%.1f°F", [celsius floatValue] * 1.8 + 32.0];
}

NSString *cycles() {
	io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
	if (powerSource) {
		CFMutableDictionaryRef batteryDictionaryRef = NULL;
		if (IORegistryEntryCreateCFProperties(powerSource, &batteryDictionaryRef, 0, 0) == KERN_SUCCESS) {
			int cycles = -1;
			CFNumberRef cyclesRef = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("CycleCount"), kCFAllocatorDefault, 0);
			CFNumberGetValue(cyclesRef, kCFNumberIntType, &cycles);
			CFRelease(cyclesRef);
			return [NSString stringWithFormat:@"%d", cycles];
		}
	}
	return @"-";
}

int maxCapacity() {
	io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
	if (powerSource) {
		CFMutableDictionaryRef batteryDictionaryRef = NULL;
		if (IORegistryEntryCreateCFProperties(powerSource, &batteryDictionaryRef, 0, 0) == KERN_SUCCESS) {
			int maxCapacity = -1;
			CFNumberRef maxCapRef = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("AppleRawMaxCapacity"), kCFAllocatorDefault, 0);
			CFNumberGetValue(maxCapRef, kCFNumberIntType, &maxCapacity);
			CFRelease(maxCapRef);
			return maxCapacity;
		}
	}
	return -1;
}

int designCapacity() {
	io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
	if (powerSource) {
		CFMutableDictionaryRef batteryDictionaryRef = NULL;
		if (IORegistryEntryCreateCFProperties(powerSource, &batteryDictionaryRef, 0, 0) == KERN_SUCCESS) {
			int designCapacity = -1;
			CFNumberRef designCapRef = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("DesignCapacity"), kCFAllocatorDefault, 0);
			CFNumberGetValue(designCapRef, kCFNumberIntType, &designCapacity);
			CFRelease(designCapRef);
			return designCapacity;
		}
	}
	return -1;
}

NSString *amperage() {
	io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
	if (powerSource) {
		CFMutableDictionaryRef batteryDictionaryRef = NULL;
		if (IORegistryEntryCreateCFProperties(powerSource, &batteryDictionaryRef, 0, 0) == KERN_SUCCESS) {
			int amperage = -1;
			CFNumberRef amperageRef = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("InstantAmperage"), kCFAllocatorDefault, 0);
			CFNumberGetValue(amperageRef, kCFNumberIntType, &amperage);
			CFRelease(amperageRef);
			return [NSString stringWithFormat:@"%d mA", amperage];
		}
	}
	return @"- mA";
}

NSString *voltage() {
	io_service_t powerSource = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPMPowerSource"));
	if (powerSource) {
		CFMutableDictionaryRef batteryDictionaryRef = NULL;
		if (IORegistryEntryCreateCFProperties(powerSource, &batteryDictionaryRef, 0, 0) == KERN_SUCCESS) {
			float voltage = -1;
			CFNumberRef voltageRef = (CFNumberRef)IORegistryEntryCreateCFProperty(powerSource, CFSTR("Voltage"), kCFAllocatorDefault, 0);
			CFNumberGetValue(voltageRef, kCFNumberFloatType, &voltage);
			CFRelease(voltageRef);
			return [NSString stringWithFormat:@"%.1f V", voltage / 1000];
		}
	}
	return @"- V";
}

@implementation AMPStatsController
- (id)init {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"AMPReloadStatsController" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"SBUIACStatusChangedNotification" object:nil];
	}
	return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.tableView.delegate = self;
    self.tableView.dataSource = self;
	self.tableView.separatorColor = [UIColor clearColor];
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.userInteractionEnabled = NO;
    [self.view addSubview:self.tableView];

	[NSLayoutConstraint activateConstraints:@[
		[self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
		[self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
	]];
}
- (double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
	return 44.0;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 8;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *identifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	}
	cell.backgroundColor = [UIColor clearColor];
	UIListContentConfiguration *content = [cell defaultContentConfiguration];
	[content setText:[self titleForRow:indexPath.row]];
	[content.textProperties setColor:[UIColor whiteColor]];
	[content setSecondaryText:[self detailForRow:indexPath.row]];
	[content.secondaryTextProperties setColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
	[content.secondaryTextProperties setFont:[UIFont systemFontOfSize:18]];
	[content setPrefersSideBySideTextAndSecondaryText:YES];
	[cell setContentConfiguration:content];

	return cell;
}
- (NSString *)titleForRow:(NSInteger)row {
	NSString *title;
	switch (row) {
		case 0:
			title = @"Charging";
			break;
		case 1:
			title = @"Cycles";
			break;
		case 2:
			title = @"Temperature";
			break;
		case 3:
			title = @"Health";
			break;
		case 4:
			title = @"Max Capacity";
			break;
		case 5:
			title = @"Design Capacity";
			break;
		case 6:
			title = @"Amperage";
			break;
		case 7:
			title = @"Voltage";
	}
	return title;
}
- (NSString *)detailForRow:(NSInteger)row {
	NSString *detail;
	switch (row) {
		case 0:
			detail = batteryCharging();
			break;
		case 1:
			detail = cycles();
			break;
		case 2:
			detail = [NSString stringWithFormat:@"%@/%@", celsiusTemperature(), fahrenheitTemperature()];
			break;
		case 3:
			detail = [NSString stringWithFormat:@"%0.f%%", (CGFloat)maxCapacity() / (CGFloat)designCapacity() * 100];
			break;
		case 4:
			detail = [NSString stringWithFormat:@"%d mAh", maxCapacity()];
			break;
		case 5:
			detail = [NSString stringWithFormat:@"%d mAh", designCapacity()];
			break;
		case 6:
			detail = amperage();
			break;
		case 7:
			detail = voltage();
			break;
	}
	return detail;
}
- (void)reloadData {
	[self.tableView reloadData];
}
- (BOOL)_canShowWhileLocked {
	return YES;
}
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
	if (objc_getClass("_PMLowPowerMode")) {
		_PMLowPowerMode *lowPowerMode = [objc_getClass("_PMLowPowerMode") sharedInstance];
		BOOL active = [lowPowerMode getPowerMode] == 1;
		[lowPowerMode setPowerMode:!active fromSource:@"SpringBoard"];
	} else {
		long long state = [[objc_getClass("_CDBatterySaver") batterySaver] getPowerMode];
		if (state == 0) {
			[[objc_getClass("_CDBatterySaver") batterySaver] setPowerMode:1 error:nil];
		} 
		if (state == 1) {
			[[objc_getClass("_CDBatterySaver") batterySaver] setPowerMode:0 error:nil];
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
%new
- (UIColor *)ampereFillColor {
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
}
- (UIColor *)_batteryFillColor { // Return default or custom fill colors based on charging state
	return [self ampereFillColor];
}
%end

%hook _UIStatusBarDataBatteryEntry
- (NSString *)detailString {
	return @""; // Return empty string to keep automatic sizing
}
%end

%hook BCUIRowView
%property (nonatomic, strong) _UIBatteryView *ampereBatteryView;
- (void)_configureBatteryViewIfNecessary {
	%orig;
	BCUIBatteryView *batteryView = MSHookIvar<BCUIBatteryView *>(self, "_batteryView");
	
	if (!(kSLSystemVersioniOS16)) {
		if (!self.ampereBatteryView) self.ampereBatteryView = [[%c(_UIBatteryView) alloc] initWithSizeCategory:0];
		self.ampereBatteryView.translatesAutoresizingMaskIntoConstraints = NO;
		
		[self addSubview:self.ampereBatteryView];
		[NSLayoutConstraint activateConstraints:@[
			[self.ampereBatteryView.widthAnchor constraintEqualToAnchor:batteryView.widthAnchor constant:-1],
			[self.ampereBatteryView.heightAnchor constraintEqualToAnchor:batteryView.heightAnchor],
			[self.ampereBatteryView.centerXAnchor constraintEqualToAnchor:batteryView.centerXAnchor],
			[self.ampereBatteryView.centerYAnchor constraintEqualToAnchor:batteryView.centerYAnchor],
		]];
		batteryView.hidden = YES;

		[self.ampereBatteryView setChargePercent:batteryView.chargePercent];
		[self.ampereBatteryView setChargingState:batteryView.chargingState];
	}
}
- (void)_configurePercentChargeLabelIfNecessary {
	
}
%end
%end

%group XVI
%hook _UIStaticBatteryView
- (void)setShowsPercentage:(BOOL)arg0 {
	%orig(YES);
}
- (void)_createFillLayer {
	%orig;
	[self setShowsPercentage:YES];
}
%end

%hook _UIBatteryView
- (BOOL)_batteryTextIsCutout {
	if (textStyle == 1 || [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.CarPlayApp"]) {
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
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		[path applyTransform:CGAffineTransformMakeTranslation(1, 0)]; // Shift pin 1 px, done because setting line interspace width to fill body adds border
	}
	return path;
}
- (void)_updateFillLayer {
	%orig;
	[self.fillLayer setCornerRadius:([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? 4.0 : 3.5]; // Set fill corner radius whenever layer updates
	[self.fillLayer setCornerCurve:@"circular"];
}
- (void)_updatePercentage {
	%orig;
	self.percentageLabel.font = [UIFont systemFontOfSize:((self.chargingState == 1 || self.chargePercent == 1.0) && fontSize > 10) ? 10 : fontSize weight:((batterySizing == 1) ? UIFontWeightHeavy : UIFontWeightBold)]; // Set custom percentage font size
	if (showBolt && self.chargingState == 1 && self.chargePercent != 1.0) { // Show bolt next to percentage label text
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
+ (CGFloat)_lineWidthAndInterspaceForIconSize:(NSInteger)arg0 {
	return 0;
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
	fill.maskedCorners = (self.chargePercent > 0.82) ? (kCALayerMaxXMaxYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner) : (kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner); // Rounded corners always on leading edge, flat on trailing until above 92% to match stock radius
	fill.bounds = CGRectMake(fill.bounds.origin.x - 1, fill.bounds.origin.y, fill.bounds.size.width, self.bounds.size.height);
	return fill;
}
- (CGRect)_bodyRectForTraitCollection:(id)arg0 {
	CGRect bodyRect = %orig;
	return CGRectMake(bodyRect.origin.x, bodyRect.origin.y, bodyRect.size.width - 1, bodyRect.size.height); // Resize view height to better replicate iOS 16
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

%group AmpereCarPlay
%hook _UIBatteryView
- (void)setSaverModeActive:(BOOL)arg1 {
	%orig;
	[self _updatePercentage];
}
- (void)_createBodyLayers {
	%orig;
	[self _updatePercentageFont];
}
- (BOOL)showsPercentage {
	return YES;
}
- (BOOL)_shouldShowBolt {
	return NO;
}
- (BOOL)showsInlineChargingIndicator {
	return NO;
}
- (CGFloat)_lineWidthAndInterspaceForTraitCollection:(id)arg0 {
	return 0;
}
- (void)_updatePercentage {
	%orig;
	[self.percentageLabel setFrame:CGRectMake(-1, self.bounds.origin.y, self.bounds.size.width -0.5, self.bounds.size.height)];
	[self.percentageLabel setTextAlignment:(NSTextAlignment)1];
	[self.percentageLabel setText:[NSString stringWithFormat:@"%.f", [self chargePercent] * 100]];
	self.percentageLabel.alpha = 1.0;
	// UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithName:@".SFUI-SemiCondensedBold" size:11];
	self.percentageLabel.font = [UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightBold]; // Set custom percentage font size
	self.percentageLabel.textColor = [self _batteryTextColor];
	// self.percentageLabel.font = [UIFont fontWithDescriptor:fontDescriptor size:11];
	if (self.chargePercent != 1.0) { // Show bolt next to percentage label text
		NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
		[attachment setBounds:CGRectMake(0, 0, roundf(self.percentageLabel.font.capHeight * 0.6), roundf(self.percentageLabel.font.capHeight))];
		[attachment setImage:[[UIImage systemImageNamed:@"bolt.fill"] imageWithTintColor:(self.saverModeActive) ? [UIColor blackColor] : [self _batteryTextColor]]];
	
		NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.f", [self chargePercent] * 100]];
		[atr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];		
		self.percentageLabel.attributedText = atr;
	}
	self.percentageLabel.layer.allowsGroupBlending = YES;
	self.percentageLabel.layer.allowsGroupOpacity = YES;
	self.percentageLabel.layer.compositingFilter = (textStyle == 1) || (textStyle == 0 && (self.chargingState != 1) && !self.saverModeActive) ? kCAFilterDestOut : nil; // Enable cutout effect on text when in transparent mode or default (when not charging)

	self.pinColor = (self.chargePercent > 0.97) ? [self _batteryFillColor] : [self bodyColor];
}
- (CALayer *)fillLayer {
	CALayer *fill = %orig;
	fill.maskedCorners = (self.chargePercent > 0.82) ? (kCALayerMaxXMaxYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner) : (kCALayerMinXMaxYCorner | kCALayerMinXMinYCorner); // Rounded corners always on leading edge, flat on trailing until above 92% to match stock radius
	fill.frame = CGRectMake(fill.frame.origin.x, fill.bounds.origin.y, fill.bounds.size.width - 0.5, self.bounds.size.height);
	return fill;
}
- (CAShapeLayer *)bodyShapeLayer {
	CAShapeLayer *bodyLayer = %orig;
	bodyLayer.fillColor = [[UIColor labelColor] colorWithAlphaComponent:0.4].CGColor; // Fill exisiting battery view completely
	return bodyLayer;
}
- (void)_updateFillLayer {
	%orig;
	[self.fillLayer setCornerRadius:3]; // Set fill corner radius whenever layer updates
	[self.fillLayer setCornerCurve:@"circular"];
}
- (UIColor *)pinColor {
	return (self.chargePercent > 0.97) ? [self _batteryFillColor] : [self bodyColor]; // Set pin color to fill color, but only when charge exceeds frame of regular battery body
}
- (CGRect)_bodyRectForTraitCollection:(id)arg0 {
	CGRect bodyRect = %orig;
	return CGRectMake(bodyRect.origin.x, bodyRect.origin.y, bodyRect.size.width - 1, bodyRect.size.height); // Resize view height to better replicate iOS 16
} 
+ (id)_pinBezierPathForSize:(struct CGSize )arg0 complex:(BOOL)arg1 {
	UIBezierPath *path = %orig;
	[path applyTransform:CGAffineTransformMakeTranslation(2, 0)]; // Shift pin 1 px, done because setting line interspace width to fill body adds borderr
	return path;
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
%end
%end

%group BatteryInfo
%hook CCUIToggleViewController
- (void)viewDidLoad {
	%orig;
	if ([self.module isKindOfClass:%c(CCUILowPowerModule)]) {
		AMPStatsController *statsController = [[AMPStatsController alloc] init];
		if (![self.view.subviews containsObject:statsController.view]) {
			statsController.view.translatesAutoresizingMaskIntoConstraints = NO;
			statsController.view.tag = 9999;
			statsController.view.hidden = YES;
			[self addChildViewController:statsController];
			[self.view addSubview:statsController.view];

			[NSLayoutConstraint activateConstraints:@[
				[statsController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
				[statsController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
				[statsController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
				[statsController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
			]];
		}
	}
}
- (BOOL)shouldFinishTransitionToExpandedContentModule {
	if ([self.module isKindOfClass:%c(CCUILowPowerModule)]) {
		return YES;
	}
	return %orig;
}
- (CGFloat)preferredExpandedContentHeight {
	if ([self.module isKindOfClass:%c(CCUILowPowerModule)]) {
		return HEIGHT * 0.5;
	}
	return %orig;
}
- (CGFloat)preferredExpandedContentWidth {
	if ([self.module isKindOfClass:%c(CCUILowPowerModule)]) {
		return WIDTH * 0.6;
	}
	return %orig;
}
- (void)willTransitionToExpandedContentMode:(BOOL)arg0 {
	%orig;
	if ([self.module isKindOfClass:%c(CCUILowPowerModule)]) {
		UIView *statsView = (UIView *)[self.view viewWithTag:9999];
		statsView.hidden = !arg0;

		self.buttonView.hidden = arg0;

		if (arg0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AMPReloadStatsController" object:nil];
		}
	}
}
%end

%hook CCUIContentModuleContainerViewController
- (BOOL)clickPresentationInteractionShouldPresent:(id)arg0 {
	if ([self.moduleIdentifier isEqualToString:@"com.apple.control-center.LowPowerModule"] && SYSTEM_VERSION_GREATER_THAN(@"15.0")) {
		return YES;
	}
	return %orig;
}
- (void)viewDidLoad {
	%orig;
	if ([self.moduleIdentifier isEqualToString:@"com.apple.control-center.LowPowerModule"] && SYSTEM_VERSION_GREATER_THAN(@"15.0")) {
		AMPStatsController *statsController = [[AMPStatsController alloc] init];
		if (![self.view.subviews containsObject:statsController.view]) {
			statsController.view.translatesAutoresizingMaskIntoConstraints = NO;
			statsController.view.tag = 9999;
			statsController.view.hidden = YES;
			[self addChildViewController:statsController];
			[self.view addSubview:statsController.view];

			[NSLayoutConstraint activateConstraints:@[
				[statsController.view.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
				[statsController.view.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
				[statsController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
				[statsController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
				[statsController.view.heightAnchor constraintEqualToConstant:HEIGHT * 0.6],
			]];
		}
	}
}
- (void)transitionToExpandedMode:(BOOL)arg0 {
	%orig;
	if ([self.moduleIdentifier isEqualToString:@"com.apple.control-center.LowPowerModule"] && SYSTEM_VERSION_GREATER_THAN(@"15.0")) {
		UIView *statsView = (UIView *)[self.view viewWithTag:9999];
		statsView.hidden = !arg0;

		self.contentViewController.view.hidden = arg0;
		CCUIContentModuleContentContainerView *containerView = self.contentContainerView;
		MTMaterialView *materialView = MSHookIvar<MTMaterialView *>(containerView, "_moduleMaterialView");
		materialView.hidden = arg0;

		if (arg0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AMPReloadStatsController" object:nil];
		}
	}
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
	NSNumber *useStatsModuleValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"useStatsModule" inDomain:domain];
	useStatsModule = (useStatsModuleValue) ? [useStatsModuleValue boolValue] : YES;

	NSNumber *textStyleValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain];
	textStyle = (textStyleValue) ? [textStyleValue integerValue] : 0;
	NSNumber *fontSizeValue = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"fontSize" inDomain:domain];
	fontSize = (fontSizeValue) ? [fontSizeValue integerValue] : 8;
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
			if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.CarPlayApp"]) {
				%init(AmpereCarPlay);
			}
		}
		if (useStatsModule) {
			%init(BatteryInfo);
		}
	}
}