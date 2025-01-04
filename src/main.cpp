#include <format>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include "logger.hpp"

#define __detailsPrefix "⟹"
#define __fontBold "\x1b[1m"
#define __fontNormal "\x1b[0m"
#define bold(text) __fontBold text __fontNormal

namespace logger {
auto print(Report rpt, bool shouldThrow) -> void {
    // log the severity level
    switch (rpt.level) {
        case LogLevel::Debug:   std::cout << bold("[D] Debug:   "); break;
        case LogLevel::Info:    std::cout << bold("[I] Info:    "); break;
        case LogLevel::Warning: std::cout << bold("[W] Warning: "); break;
        case LogLevel::Error:   std::cout << bold("[E] Error:   "); break;
    };

    std::cout << rpt.message << std::endl;
    if (shouldThrow) throw std::runtime_error("Unhandled exception has occured.");
}

auto print(const char* filepath, Report rpt, bool shouldThrow) -> void {
    // log the error message
    print(rpt, false);

    // log the error line
    std::ifstream stream(filepath);
    if (!stream)
        print((Report) {
                .level = LogLevel::Error,
                .message = std::format("cannot open file '{}'", filepath).c_str()
            }, true);

    uint cur = 1;
    std::string line;
    while (std::getline(stream, line) && cur++ != rpt.line);
    stream.close();

    std::cout << __detailsPrefix "   " << line << std::endl << "    ";
    
    cur = 1;
    while (cur < (rpt.start + rpt.count)) {
        std::cout << (cur >= rpt.start ? '^' : ' ');
        cur++;
    }

    std::cout << std::endl;
    if (shouldThrow) throw std::runtime_error("Unhandled exception occured.");
}
}  // namespace logger
