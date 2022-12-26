#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
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

@interface PSSpecifier : NSObject
@property (nonatomic, retain) NSString *name;   
- (NSDictionary *)properties;
@end

@interface PSTableCell (Ampere)
- (void)setValue:(id)arg0;
@end

@interface PSControlTableCell : PSTableCell
- (UIControl *)control;
- (void)controlChanged:(UIControl *)arg1;
@end

@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(id)specifier;
- (void)controlChanged:(id)arg1;
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
@property (nonatomic, strong) AmpSwitch *enableSwitch;
- (void)setEnableSwitchState;
@end
