#include "AMPRootListController.h"

@import SafariServices;

@implementation AMPRootListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}
- (UITableViewStyle)tableViewStyle {
	return UITableViewStyleInsetGrouped;
}
- (instancetype)init {
	self = [super init];
	if (self) {
		self.enableSwitch = [[AmpSwitch alloc] initWithSize:AmpSwitchSizeBig style:AmpSwitchStyleDefault state:AmpSwitchStateOff];
		self.enableSwitch.delegate = self;
		self.enableSwitch.thumbOnTintColor = [UIColor systemGreenColor];
		self.enableSwitch.thumbOffTintColor = [UIColor labelColor];
		self.enableSwitch.trackOnTintColor = [UIColor secondaryLabelColor];
		self.enableSwitch.trackOffTintColor = [UIColor secondaryLabelColor];
		[self setupButtonMenu];
	}
	return self;
}
- (void)setupButtonMenu {
	[self.enableSwitch addTarget:self action:@selector(toggleState:) forControlEvents:UIControlEventTouchUpInside];
	
	UIAction *respring = [UIAction actionWithTitle:@"Respring" image:[UIImage systemImageNamed:@"gearshape.fill"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
		[self respring];
	}];

	UIAction *reset = [UIAction actionWithTitle:@"Reset Settings" image:[UIImage systemImageNamed:@"gearshape.fill"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
		[self reset];
	}];
	reset.attributes = UIMenuElementAttributesDestructive;

	UIMenu *menuActions = [UIMenu menuWithTitle:@"" children:@[respring, reset]];
	UIBarButtonItem *optionsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gearshape.fill"] menu:menuActions];
	optionsItem.tintColor = [UIColor systemGreenColor];

	self.navigationItem.rightBarButtonItems = @[optionsItem];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self setEnableSwitchState];
	[self updateSpecifiers];

	self.view.tintColor = [UIColor systemGreenColor];
	[[UIApplication sharedApplication] keyWindow].tintColor = [UIColor systemGreenColor];
	[self.navigationController.navigationBar setPrefersLargeTitles:YES];
	[self.navigationController.navigationItem.navigationBar sizeToFit];
	_table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
}
- (void)viewWillDisappear:(BOOL)animated {
	[[UIApplication sharedApplication] keyWindow].tintColor = nil;
	[super viewWillDisappear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];

	self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
	
	self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    self.enableSwitch.translatesAutoresizingMaskIntoConstraints = NO;

	self.batteryView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.batteryView.contentMode = UIViewContentModeScaleAspectFit;
	self.batteryView.translatesAutoresizingMaskIntoConstraints = NO;
	self.batteryView.image = [[UIImage systemImageNamed:@"bolt.fill"] imageWithTintColor:[UIColor systemGreenColor]];
	self.batteryView.tintColor = [UIColor systemGreenColor];
	self.batteryView.layer.shadowOpacity = 1.0f;
    self.batteryView.layer.shadowOffset = CGSizeZero;
	self.batteryView.layer.shadowColor = [UIColor systemGreenColor].CGColor;

	CABasicAnimation *glowanimation = [CABasicAnimation animation];
	glowanimation.keyPath = @"shadowRadius";
	glowanimation.fromValue = @0;
	glowanimation.toValue = @15;
	glowanimation.autoreverses = YES;
	glowanimation.duration = 1.0;
	glowanimation.repeatCount = HUGE_VALF;

	[self.batteryView.layer addAnimation:glowanimation forKey:@"glow"];

	[self.headerView addSubview:self.enableSwitch];
	[self.headerView addSubview:self.batteryView];

    [NSLayoutConstraint activateConstraints:@[
       	[self.enableSwitch.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor constant:-20],
		[self.enableSwitch.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor],
		[self.enableSwitch.widthAnchor constraintEqualToConstant:50],
		[self.enableSwitch.heightAnchor constraintEqualToConstant:40],
		[self.batteryView.widthAnchor constraintEqualToConstant:150],
		[self.batteryView.heightAnchor constraintEqualToConstant:75],
		[self.batteryView.centerXAnchor constraintEqualToAnchor:self.headerView.centerXAnchor constant:0],
		[self.batteryView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor constant:30],
	]];
	_table.tableHeaderView = self.headerView;
}
- (void)updateSpecifiers {
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"16.0")) {
		NSArray *fontSpecifiers = [self specifiersInGroup:2];
		NSArray *boltSpecifiers = [self specifiersInGroup:3];
		NSArray *gestureSpecifiers = [self specifiersInGroup:4];
		[self removeContiguousSpecifiers:fontSpecifiers animated:NO];
		[self removeContiguousSpecifiers:boltSpecifiers animated:NO];
		[self removeContiguousSpecifiers:gestureSpecifiers animated:NO];
	}
}
- (void)reloadSpecifiers {
	[super reloadSpecifiers];
	[self updateSpecifiers];
}
- (BOOL)shouldReloadSpecifiersOnResume {
	return YES;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	tableView.tableHeaderView = self.headerView;
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		if (indexPath.section == 4) {
			if (indexPath.row == 0) {
				[(PSTableCell *)cell setCellEnabled:NO];
				[(PSTableCell *)cell.detailTextLabel setText:@"Not available on iPad"];
			}
		}
	}
	return cell;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if ([self tableView:tableView titleForHeaderInSection:section] != nil) {

		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
		titleLabel.textColor = [UIColor secondaryLabelColor];
		titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
		titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];

		NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
		[attachment setBounds:CGRectMake(0, 0, roundf(titleLabel.font.capHeight * 1.5), roundf(titleLabel.font.capHeight))];
		
		switch (section) {
			case 0:
				[attachment setImage:[[UIImage systemImageNamed:@"bolt.fill.batteryblock.fill"] imageWithTintColor:[UIColor systemGreenColor]]];
				break;
			case 1:
				[attachment setImage:[[UIImage systemImageNamed:@"paintpalette.fill"] imageWithTintColor:[UIColor systemGreenColor]]];
				break;
			case 2:
				[attachment setImage:[[UIImage systemImageNamed:@"textformat"] imageWithTintColor:[UIColor systemGreenColor]]];
				break;
			case 3:
				[attachment setImage:[[UIImage systemImageNamed:@"bolt.fill"] imageWithTintColor:[UIColor systemGreenColor]]];
				break;
			case 4:
				[attachment setImage:[[UIImage systemImageNamed:@"hand.point.up.fill"] imageWithTintColor:[UIColor systemGreenColor]]];
				break;
			case 5:
				[attachment setImage:[[UIImage systemImageNamed:@"link"] imageWithTintColor:[UIColor systemGreenColor]]];
				break;
			default:
				break;
		}

		NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
		[baseString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[@" " stringByAppendingString:[self tableView:tableView titleForHeaderInSection:section]]]];

		titleLabel.attributedText = baseString;
		return titleLabel;
	}
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if ([self tableView:tableView titleForHeaderInSection:section] != nil) {
		return 40;
	}
	return 10;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == [self numberOfGroups] - 1) {
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width / 2) - 100, 0, 200, 100)];
		titleLabel.numberOfLines = 2;
		titleLabel.textColor = [UIColor secondaryLabelColor];
		titleLabel.textAlignment = NSTextAlignmentCenter;
		
		NSString *primary = @"Ampere";
		NSString *secondary = @"v1.0.6 © MTAC";

		NSMutableAttributedString *final = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", primary, secondary]];
		[final addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold] range:[final.string rangeOfString:primary]];
		[final addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular] range:[final.string rangeOfString:secondary]];

		titleLabel.attributedText = final;
		return titleLabel;
	}
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self numberOfGroups] - 1) {
		return 50;
	}
	return 0;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 3) {
		if (indexPath.row == 0) {
			[[NSBundle bundleWithPath:@"/System/Library/Frameworks/SafariServices.framework"] load];
			if ([SFSafariViewController class] != nil) {
				SFSafariViewController *safariView = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/MTACS/Ampere"]];
				if ([safariView respondsToSelector:@selector(setPreferredControlTintColor:)]) {
					safariView.preferredControlTintColor = [UIColor systemGreenColor];
				}
				[self.navigationController presentViewController:safariView animated:YES completion:nil];
			}
		}
	}
}
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
	UISwipeActionsConfiguration *swipeActions;
	PSTableCell *cell = (PSTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	NSMutableArray *actions = [NSMutableArray new];
	if ([cell isKindOfClass:NSClassFromString(@"AmpSwitchCell")] && indexPath.section == 1) {
		UIContextualAction *colorPickerAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
			[(AmpSwitchCell *)cell selectColor];
			completionHandler(YES);
		}];
		colorPickerAction.backgroundColor = [(AmpSwitchCell *)cell selectedColor]; // [UIColor tableCellGroupedBackgroundColor];
		colorPickerAction.image = [UIImage systemImageNamed:@"paintbrush.pointed.fill"];
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:cell.specifier.properties[@"key"] inDomain:domain] boolValue]) {
			[actions addObject:colorPickerAction];
		}
	} else {
		if (indexPath.section == 0) {
			if (indexPath.row == 0) {
				UIContextualAction *info = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
					UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Transparent Text" message:@"\nEnabling transparent text allows the background of the current app to show through the battery's percentage text. This is done to replicate iOS 16's styling, and works best on Homescreen & Lockscreen" preferredStyle:UIAlertControllerStyleAlert];
					[alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
					[self presentViewController:alertController animated:YES completion:nil];
					completionHandler(YES);
				}];

				info.backgroundColor = [UIColor tableCellGroupedBackgroundColor];
				info.image = [UIImage systemImageNamed:@"info.circle.fill"];

				[actions addObject:info];
			}
		} else if (indexPath.section == 2) {
			if (indexPath.row == 0) {
				UIContextualAction *reset = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
					[[NSUserDefaults standardUserDefaults] setObject:@8 forKey:@"fontSize" inDomain:domain];
					[[NSUserDefaults standardUserDefaults] synchronize];
					[self reloadSpecifier:cell.specifier];
					completionHandler(YES);
				}];

				reset.backgroundColor = [UIColor tableCellGroupedBackgroundColor];
				reset.image = [UIImage systemImageNamed:@"arrow.counterclockwise.circle"];

				[actions addObject:reset];
			}
		}
	}
	swipeActions = [UISwipeActionsConfiguration configurationWithActions:actions];
	swipeActions.performsFirstActionWithFullSwipe = YES;
	return swipeActions;
}
- (void)setEnableSwitchState {
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled" inDomain:domain] boolValue]) {
		[[self enableSwitch] setOn:NO animated:NO];
	} else {
		[[self enableSwitch] setOn:YES animated:NO];
	}
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);
}
- (void)switchStateChanged:(AmpSwitchState)switchState {
	AudioServicesPlaySystemSound(1519);
	if (!self.enableSwitch.isOn) {
		[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"enabled" inDomain:domain];
		[self.enableSwitch setOn:YES animated:YES];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"enabled" inDomain:domain];
		[self.enableSwitch setOn:NO animated:YES];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
		[self respring];
	});
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);
}
- (void)respring {
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
	indicator.translatesAutoresizingMaskIntoConstraints = NO;

	UIAlertController *applyAlert = [UIAlertController alertControllerWithTitle:@"\n\n" message:@"\n" preferredStyle:UIAlertControllerStyleAlert];
	[applyAlert.view addSubview:indicator];

	[NSLayoutConstraint activateConstraints:@[
		[indicator.centerXAnchor constraintEqualToAnchor:applyAlert.view.centerXAnchor],
		[indicator.centerYAnchor constraintEqualToAnchor:applyAlert.view.centerYAnchor],
	]];
		
	[indicator startAnimating];
	[self presentViewController:applyAlert animated:true completion:nil];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
		pid_t pid;
		const char *args[] = {"killall", "backboardd", NULL};
		posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
	});
}
- (void)reset {
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Reset Settings" message:@"\n All settings will be restored to default and device will respring. Continue?" preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:nil]];
	[alertController addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
		[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domain];
		[self reloadSpecifiers];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
			[self respring];
		});
	}]];
	[self presentViewController:alertController animated:YES completion:nil];
}
@end

@implementation AmpColorCell
@dynamic control;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		self.accessoryView = self.control;
		self.detailTextLabel.text = [specifier.properties objectForKey:@"subtitle"];
		self.detailTextLabel.numberOfLines = 2;
		[self setCellEnabled:[[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain] integerValue] == 2];
	}
	return self;
}
- (void)setCellEnabled:(BOOL)cellEnabled {
	[super setCellEnabled:cellEnabled];
	self.control.hidden = !cellEnabled;
}
- (BOOL)cellEnabled {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain] integerValue] == 2;
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	self.control.backgroundColor = [self selectedColor];
}
- (UIButton *)newControl {
	UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
	colorButton.frame = CGRectMake(0, 0, 30, 30);
	colorButton.backgroundColor = [self selectedColor];
	colorButton.layer.masksToBounds = NO;
	colorButton.layer.cornerRadius = colorButton.frame.size.width / 2;
	[colorButton addTarget:self action:@selector(selectColor) forControlEvents:UIControlEventTouchUpInside];
	return colorButton;
}
- (void)selectColor {
	UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
	colorPickerController.delegate = self;
	colorPickerController.supportsAlpha = NO;
	colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
	colorPickerController.modalInPresentation = YES;
	colorPickerController.selectedColor = [self selectedColor];
	[[self _viewControllerForAncestor] presentViewController:colorPickerController animated:YES completion:nil]; 
}
- (UIColor *)selectedColor {
	NSDictionary *colorDict = [[NSUserDefaults standardUserDefaults] objectForKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	return colorDict ? [UIColor colorWithRed:[colorDict[@"red"] floatValue] green:[colorDict[@"green"] floatValue] blue:[colorDict[@"blue"] floatValue] alpha:1.0] : [UIColor secondaryLabelColor];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
	[[NSUserDefaults standardUserDefaults] setObject:[self dictionaryForColor:viewController.selectedColor] forKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.control.backgroundColor = [self selectedColor];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);
}
- (NSDictionary *)dictionaryForColor:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
	return colorDict;
}
@end

@implementation AmpStepperCell
@dynamic control;
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		self.accessoryView = self.control;
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.numberOfLines = 2;
	}
	return self;
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	self.control.minimumValue = [specifier.properties[@"min"] doubleValue];
	self.control.maximumValue = [specifier.properties[@"max"] doubleValue];
	[self _updateLabel];
}
- (void)setCellEnabled:(BOOL)cellEnabled {
	[super setCellEnabled:cellEnabled];
	self.control.enabled = cellEnabled;
}
- (UIStepper *)newControl {
	UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
	stepper.continuous = NO;
	return stepper;
}
- (NSNumber *)controlValue {
	return @(self.control.value);
}
- (void)setValue:(NSNumber *)value {
	[super setValue:value];
	self.control.value = value.doubleValue;
}
- (void)controlChanged:(UIStepper *)stepper {
	[super controlChanged:stepper];
	[self _updateLabel];
}
- (void)_updateLabel {
	if (!self.control) {
		return;
	}
	self.textLabel.text = [NSString stringWithFormat:self.specifier.name, (int)self.control.value];
	[self setNeedsLayout];
}
- (void)prepareForReuse {
	[super prepareForReuse];
	self.control.value = 0;
	self.control.minimumValue = 0;
	self.control.maximumValue = 100;
}
@end

@implementation AmpSwitchCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
	if (self) {
		self.accessoryView = self.control;
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.numberOfLines = [specifier.properties[@"subtitleLines"] intValue] ?: 2;
	}
	return self;
}
- (id)newControl {
	AmpSwitch *switchControl = [[AmpSwitch alloc] initWithSize:AmpSwitchSizeNormal state:AmpSwitchStateOff];
	switchControl.delegate = self;
	switchControl.thumbOnTintColor = [UIColor systemGreenColor];
	switchControl.thumbOffTintColor = [UIColor labelColor];
	switchControl.trackOnTintColor = [UIColor secondaryLabelColor];
	switchControl.trackOffTintColor = [UIColor secondaryLabelColor];
	return switchControl;
}
- (void)switchStateChanged:(AmpSwitchState)currentState {
	AudioServicesPlaySystemSound(1519);
}
- (void)selectColor {
	UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
	colorPickerController.delegate = self;
	colorPickerController.supportsAlpha = NO;
	colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
	colorPickerController.modalInPresentation = YES;
	colorPickerController.selectedColor = [self selectedColor];
	[[self _viewControllerForAncestor] presentViewController:colorPickerController animated:YES completion:nil]; 
}
- (UIColor *)selectedColor {
	NSDictionary *colorDict = [[NSUserDefaults standardUserDefaults] objectForKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	return colorDict ? [UIColor colorWithRed:[colorDict[@"red"] floatValue] green:[colorDict[@"green"] floatValue] blue:[colorDict[@"blue"] floatValue] alpha:1.0] : [UIColor secondaryLabelColor];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
	[[NSUserDefaults standardUserDefaults] setObject:[self dictionaryForColor:viewController.selectedColor] forKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	[[NSUserDefaults standardUserDefaults] synchronize];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);
}
- (NSDictionary *)dictionaryForColor:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
	return colorDict;
}
@end

@implementation AmpSelectorCell
@dynamic control;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
	if (self) {
		self.accessoryView = self.control;
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.numberOfLines = 1;
	}
	return self;
}
- (id)newControl {
	UIButton *selectorButton = [UIButton buttonWithType:UIButtonTypeCustom];
	selectorButton.frame = CGRectMake(0, 0, 120, 32);
	selectorButton.menu = [self menu];
	selectorButton.showsMenuAsPrimaryAction = YES;
	selectorButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	[selectorButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
	
	[self _updateControl];
	return selectorButton;
}
- (UIMenu *)menu {
	UIAction *defaultAction = [UIAction actionWithTitle:@"Default" image:[UIImage systemImageNamed:@"applelogo"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
		[[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"textStyle" inDomain:domain];
		[self _updateControl];
	}];
	UIAction *transparentAction = [UIAction actionWithTitle:@"Transparent" image:[UIImage systemImageNamed:@"circle"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
		[[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"textStyle" inDomain:domain];
		[self _updateControl];
	}];
	UIAction *customAction = [UIAction actionWithTitle:@"Custom" image:[UIImage systemImageNamed:@"paintpalette.fill"] identifier:nil handler:^(__kindof UIAction *_Nonnull action) {
		[[NSUserDefaults standardUserDefaults] setObject:@2 forKey:@"textStyle" inDomain:domain];
		[self _updateControl];
	}];

	switch ([[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain] integerValue]) {
		case 0:
			defaultAction.state = UIMenuElementStateOn;
			transparentAction.state = UIMenuElementStateOff;
			customAction.state = UIMenuElementStateOff;
			break;
		default:
		case 1:
			defaultAction.state = UIMenuElementStateOff;
			transparentAction.state = UIMenuElementStateOn;
			customAction.state = UIMenuElementStateOff;
			break;
		case 2:
			defaultAction.state = UIMenuElementStateOff;
			transparentAction.state = UIMenuElementStateOff;
			customAction.state = UIMenuElementStateOn;
			break;
	}

	UIMenu *menuActions = [UIMenu menuWithTitle:@"" children:@[customAction, transparentAction, defaultAction]];
	return menuActions;
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	[self _updateControl];
}
- (void)_updateControl {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/preferences.changed", nil, nil, true);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);
	NSString *title;
	switch ([[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain] integerValue]) {
		case 0:
			title = @"Default ›";
			break;
		default:
		case 1:
			title = @"Transparent ›";
			break;
		case 2:
			title = @"Custom ›";
			break;
	}
	[(UIButton *)self.control setTitle:title forState:UIControlStateNormal];
	[(UIButton *)self.control setMenu:[self menu]];
	[[self _viewControllerForAncestor] reloadSpecifiers];
}
@end

@implementation AmpCodeCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
	if (self) {
		self.accessoryView = [[UIImageView alloc] initWithImage:[[UIImage systemImageNamed:@"network"] imageWithTintColor:[UIColor secondaryLabelColor]]];
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		self.detailTextLabel.numberOfLines = 1;
	}
	return self;
}
@end