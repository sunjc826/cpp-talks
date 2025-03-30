#ifndef CURRENT_VERSION
#   define CURRENT_VERSION 1
#endif
#if CURRENT_VERSION == 1
#define v1_inline inline
#define v2_inline
#elif CURRENT_VERSION == 2
#define v1_inline
#define v2_inline inline
#else
#   error "Bad CURRENT_VERSION " CURRENT_VERSION
#endif

v1_inline namespace v1
{
    char const * myfunc()
    {
        return "v1_myfunc";
    }
}

v2_inline namespace v2
{
    char const * myfunc()
    {
        return "v2_myfunc";
    }
}

#include <cstdio>
int main()
{
    puts(myfunc());
}
