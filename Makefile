# A sample Makefile for building Google Test and using it in user
# tests.  Please tweak it to suit your environment and project.  You
# may want to move it to your project's root directory.
#
# SYNOPSIS:
#
#   make [all]  - makes everything.
#   make TARGET - makes the given target.
#   make clean  - removes all files generated by make.

# Please tweak the following variable definitions as needed by your
# project, except GTEST_HEADERS, which you can use in your own targets
# but shouldn't modify.

# Points to the root of Google Test, relative to where this file is.
# Remember to tweak this if you move this file.

.PHONY: all test coverage coverage-report

PLATFORM=UNKNOWN_OS
ifeq ($(shell uname), Linux)
  PLATFORM=linux
endif
ifeq ($(shell uname), CYGWIN_NT-4.0)
  PLATFORM=win32
endif
ifeq ($(shell uname), CYGWIN_NT-5.0)
  PLATFORM=win32
endif
ifeq ($(shell uname), CYGWIN_NT-5.1)
  PLATFORM=win32
endif
ifeq ($(shell uname), MINGW32_NT-4.0)
  PLATFORM=win32
endif
ifeq ($(shell uname), MINGW32-5.0)
  PLATFORM=win32
endif
ifeq ($(shell uname), MINGW32_NT-5.1)
  PLATFORM=win32
endif

ifeq "$(PLATFORM)" "UNKNOWN_OS"
    $(error Unknown OS)
endif

ifeq "$(PLATFORM)" "linux"
    GTEST_DIR = ./googletest/googletest
endif

ifeq "$(PLATFORM)" "win32"
    GTEST_DIR = ./googletest.cygwin/googletest
endif

# Where to find user code.
USER_DIR = ./src

# Flags passed to the preprocessor.
# Set Google Test's header directory as a system directory, such that
# the compiler doesn't generate warnings in Google Test headers.
CPPFLAGS += -isystem $(GTEST_DIR)/include

# Flags passed to the C++ compiler.
ifeq "$(PLATFORM)" "linux"
    CXXFLAGS += -std=c++11 -g -Wall -Wextra -pthread
    LDFLAGS += -lpthread
else
    CXXFLAGS += -D_WIN32_WINNT=0x0501 -std=gnu++0x -g -Wall -Wextra
endif

BUILD_DIR = ./build
TESTS = $(BUILD_DIR)/md_replay

ifeq ($(MAKECMDGOALS),test)
	BUILD_DIR = ./build.test
	TESTS = $(BUILD_DIR)/md_replay_unittest
endif

ifeq ($(MAKECMDGOALS),coverage)
	BUILD_DIR = ./build.coverage
	EXTRA_CXXFLAGS += -fprofile-arcs -ftest-coverage
	TESTS = $(BUILD_DIR)/md_replay_coverage
endif

GCOV_DIR = ./gcov.report

# All Google Test headers.  Usually you shouldn't change this
# definition.
GTEST_HEADERS = $(wildcard $(GTEST_DIR)/include/gtest/*.h) \
                $(wildcard $(GTEST_DIR)/include/gtest/internal/*.h)

# House-keeping build targets.

all : $(BUILD_DIR)
	make $(BUILD_DIR)/md_replay

test: $(BUILD_DIR) $(TESTS)
	$(BUILD_DIR)/md_replay_unittest

coverage: $(BUILD_DIR) $(TESTS)
	$(BUILD_DIR)/md_replay_coverage

coverage-report:
	make coverage
	gcov -o ./build.coverage feed_handler.cpp

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean :
	rm -fr ./build ./build.test ./build.coverage $(GCOV_DIR)



# Builds gtest.a and gtest_main.a.

# Usually you shouldn't tweak such internal variables, indicated by a
# trailing _.
GTEST_SRCS_ = $(wildcard $(GTEST_DIR)/src/*.cc) $(wildcard $(GTEST_DIR)/src/*.h) $(GTEST_HEADERS)

# For simplicity and to avoid depending on Google Test's
# implementation details, the dependencies specified below are
# conservative and not optimized.  This is fine as Google Test
# compiles fast and for ordinary users its source rarely changes.
$(BUILD_DIR)/gtest-all.o : $(GTEST_SRCS_)
	$(CXX) $(CPPFLAGS) -I$(GTEST_DIR) $(CXXFLAGS) -o $@ -c \
            $(GTEST_DIR)/src/gtest-all.cc

$(BUILD_DIR)/gtest_main.o : $(GTEST_SRCS_)
	$(CXX) $(CPPFLAGS) -I$(GTEST_DIR) $(CXXFLAGS) -o $@ -c \
            $(GTEST_DIR)/src/gtest_main.cc

$(BUILD_DIR)/gtest.a : $(BUILD_DIR)/gtest-all.o
	$(AR) $(ARFLAGS) $@ $^

$(BUILD_DIR)/gtest_main.a : $(BUILD_DIR)/gtest-all.o $(BUILD_DIR)/gtest_main.o
	$(AR) $(ARFLAGS) $@ $^

# Builds a sample test.  A test should link with either gtest.a or
# gtest_main.a, depending on whether it defines its own main()
# function.

RPATH = -Wl,-rpath,$(shell dirname $(shell which $(CXX)))/../lib64


$(BUILD_DIR)/feed_handler.o : $(USER_DIR)/feed_handler.cpp $(USER_DIR)/feed_handler.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(EXTRA_CXXFLAGS) -o $@ -c $(USER_DIR)/feed_handler.cpp

$(BUILD_DIR)/md_replay.o : $(USER_DIR)/md_replay.cpp $(USER_DIR)/feed_handler.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(EXTRA_CXXFLAGS) -o $@ -c $(USER_DIR)/md_replay.cpp

$(BUILD_DIR)/feed_handler_unittest.o : $(USER_DIR)/feed_handler_unittest.cpp \
                     $(USER_DIR)/feed_handler.h $(GTEST_HEADERS)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ -c $(USER_DIR)/feed_handler_unittest.cpp

$(BUILD_DIR)/md_replay_unittest : $(BUILD_DIR)/feed_handler.o $(BUILD_DIR)/feed_handler_unittest.o $(BUILD_DIR)/gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $^ -o $@ $(RPATH)

$(BUILD_DIR)/md_replay : $(BUILD_DIR)/md_replay.o $(BUILD_DIR)/feed_handler.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $^ -o $@ $(RPATH)

$(BUILD_DIR)/md_replay_coverage : $(BUILD_DIR)/feed_handler.o $(BUILD_DIR)/feed_handler_unittest.o $(BUILD_DIR)/gtest_main.a
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(LDFLAGS) $^ -o $@ $(RPATH)


