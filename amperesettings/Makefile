export ARCHS = arm64 arm64e
export TARGET = iphone:latest:15.5
export DEB_ARCH = iphoneos-arm64
export IPHONEOS_DEPLOYMENT_TARGET = 15.5
THEOS_PACKAGE_SCHEME=roothide


include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AmpereSettings

AmpereSettings_FILES = AMPRootListController.m AmpSwitch.m
AmpereSettings_FRAMEWORKS = UIKit
AmpereSettings_PRIVATE_FRAMEWORKS = Preferences
AmpereSettings_INSTALL_PATH = /Library/PreferenceBundles
AmpereSettings_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations
AmpereSettings_LDFLAGS += -lroothide

include $(THEOS_MAKE_PATH)/bundle.mk
