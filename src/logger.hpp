#pragma once
#include <sys/types.h>

namespace logger {
enum class LogLevel {
    Debug,
    Info,
    Warning,
    Error
};

struct Report final {
    uint line  = 0;
    uint start = 0;
    uint count = 0;
    LogLevel level = LogLevel::Debug;
    const char* message = "";
};

auto print(Report rpt, bool shouldThrow = false) -> void;
auto print(const char* filepath, Report rpt, bool shouldThrow = false) -> void;
}  // namespace lib
