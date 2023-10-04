#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import "AmpSwitch.h"
#import "spawn.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSString *domain = @"com.mtac.amp";

@interface NSUserDefaults (Ampere)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

@interface UIView (Ampere)
- (id)_viewControllerForAncestor;
@end

@interface UIColor (Ampere) 
+ (id)tableCellGroupedBackgroundColor;
@end

@interface UINavigationItem (Ampere)
@property (assign, nonatomic) UINavigationBar *navigationBar; 
@end

@interface PSTableCell (Ampere)
- (void)setValue:(id)arg0;
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(id)arg1 withResult:(id)arg2;
@end

@interface BSAction : NSObject
@end

@interface SBSRelaunchAction : BSAction
+ (id)actionWithReason:(id)arg1 options:(unsigned long long)arg2 targetURL:(id)arg3;
@end

@interface AmpColorCell : PSControlTableCell <UIColorPickerViewControllerDelegate>
@property (nonatomic, retain) UIButton *control;
- (NSDictionary *)dictionaryForColor:(UIColor *)color;
- (void)selectColor;
@end

@interface AmpStepperCell : PSControlTableCell
@property (nonatomic, retain) UIStepper *control;
@end

@interface AmpSwitchCell : PSSwitchTableCell <AmpSwitchDelegate, UIColorPickerViewControllerDelegate>
- (void)selectColor;
- (UIColor *)selectedColor;
@end

@interface AmpSelectorCell : PSControlTableCell
@property (nonatomic, retain) UIButton *control;
@end

@interface AmpCodeCell : PSTableCell
@end

@interface AMPRootListController : PSListController <AmpSwitchDelegate> {
    UITableView *_table;
}
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *batteryView;
@property (nonatomic, retain) UILabel *percentageLabel;
@property (nonatomic, retain) UILabel *sectionSegmentLabel;
@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) AmpSwitch *enableSwitch;
- (void)setEnableSwitchState;
@end
