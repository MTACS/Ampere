TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard Preferences
ARCHS = arm64 arm64e
SYSROOT = $(THEOS)/sdks/iPhoneOS14.2.sdk
DEBUG = 1
FINALPACKAGE = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Ampere

Ampere_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations
Ampere_FILES = Ampere.xm
Ampere_FRAMEWORKS = IOKit
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
Ampere_LDFLAGS += -lroothide
endif

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += amperesettings
include $(THEOS_MAKE_PATH)/aggregate.mk
