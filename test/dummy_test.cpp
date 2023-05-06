#include "solution.h"

#include <gtest/gtest.h>

#include <stdexcept>

TEST(dummy_test, test_abi) {
  EXPECT_THROW(throwing_func(), std::logic_error);
}
