TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Ampere

Ampere_CFLAGS = -fobjc-arc -Wdeprecated-declarations -Wno-deprecated-declarations
Ampere_FILES = Ampere.xm

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += amperesettings
include $(THEOS_MAKE_PATH)/aggregate.mk
