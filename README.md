# cpp.logger
Simple c++ library to log messages.

## USAGE
### Include
Include the library in your source file:

```cpp
#include "path/to/lib/logger.hpp"
...
```

Link the object file:

```bash
g++ ... path/to/lib/logger.a
```

### API
```cpp
enum class LogLevel {
    Debug,
    Info,
    Warning,
    Error
};
```
Defines logging severity levels.

```cpp
struct Report final {
    uint line  = 0;
    uint start = 0;
    uint count = 0;
    LogLevel level = LogLevel::Debug;
    const char* message = "";
};
```
Type defining the message to log.
