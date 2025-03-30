#ifndef CURRENT_VERSION
#   define CURRENT_VERSION 1
#endif

#if CURRENT_VERSION == 1
#   define myfunc v1_myfunc
#elif CURRENT_VERSION == 2
#   define myfunc v2_myfunc
#else
#   error "Bad version"
#endif

char const * v1_myfunc(void)
{
    return "v1_myfunc";
}

char const * v2_myfunc(void)
{
    return "v2_myfunc";
}
#include <stdio.h>
int main()
{
    puts(myfunc());    
}
