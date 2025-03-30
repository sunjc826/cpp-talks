#ifndef CURRENT_VERSION
#   define CURRENT_VERSION 1
#endif
#define CONCAT_(a, b) a ## b
#define CONCAT(a, b) CONCAT_(a, b)
#define v CONCAT(v, CURRENT_VERSION)
#define v1(func) v1_##func
#define v2(func) v2_##func

char const * v1(myfunc)(void)
{
    return "v1_myfunc";
}

char const * v2(myfunc)(void)
{
    return "v2_myfunc";
}
#include <stdio.h>
int main()
{
    puts(v(myfunc)());
}

