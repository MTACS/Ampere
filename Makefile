export ARCHS = arm64 arm64e
export TARGET = iphone:latest:15.5
export DEB_ARCH = iphoneos-arm64
export IPHONEOS_DEPLOYMENT_TARGET = 15.5
THEOS_PACKAGE_SCHEME=roothide

INSTALL_TARGET_PROCESSES = SpringBoard Preferences


DEBUG = 1
FINALPACKAGE = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Ampere

Ampere_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations
Ampere_FILES = Ampere.xm
Ampere_FRAMEWORKS = IOKit
Ampere_LDFLAGS += -lroothide

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += amperesettings
include $(THEOS_MAKE_PATH)/aggregate.mk

Ampere_CODESIGN_FLAGS = -Sentitlements.plist