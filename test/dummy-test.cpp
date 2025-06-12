#include "solution.h"

#include <catch2/catch_test_macros.hpp>

#include <stdexcept>

namespace ct_test {

TEST_CASE("ABI") {
  REQUIRE_THROWS_AS(ct::throwing_func(), std::logic_error);
}

} // namespace ct_test
