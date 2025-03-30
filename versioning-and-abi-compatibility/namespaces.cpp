#ifndef CURRENT_VERSION
#   define CURRENT_VERSION 1
#endif

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
#include <cstdio>
int main()
{
#if CURRENT_VERSION == 1
    puts(v1::myfunc());
#elif CURRENT_VERSION == 2
    puts(v2::myfunc());
#else
#   error "Bad version"
#endif
    
}
