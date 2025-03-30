#ifndef CURRENT_VERSION
#   define CURRENT_VERSION 1
#endif

#define CONCAT_(a, b) a ## b
#define CONCAT(a, b) CONCAT_(a, b)

namespace v1
{
    char const * myfunc()
    {
        return "v1_myfunc";
    }
}

namespace v2
{
    char const * myfunc()
    {
        return "v2_myfunc";
    }
}

namespace current_version = CONCAT(v, CURRENT_VERSION);

#include <cstdio>
int main()
{
    puts(current_version::myfunc());
}
