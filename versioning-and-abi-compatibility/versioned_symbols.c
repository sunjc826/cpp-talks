#include "utils.h"
#ifndef CURRENT_VERSION
#   define CURRENT_VERSION 1
#endif

#define SYMVER(version, symbol) \
    asm(".symver " #version "_" #symbol ", " #symbol "@" #version);
#define DEFAULT_SYMVER(version, symbol) \
    asm(".symver " #version "_" #symbol ", " #symbol "@@" #version);

#define v1(symbol) SYMVER(v1, symbol)
#define v2(symbol) SYMVER(v2, symbol)

#if CURRENT_VERSION == 1
#   undef v1
#   define v1(symbol) DEFAULT_SYMVER(v1, symbol)
#elif CURRENT_VERSION == 2
#   undef v2
#   define v2(symbol) DEFAULT_SYMVER(v2, symbol)
#else
#   error "Bad CURRENT_VERSION"
#endif

char const * myfunc(void);

__attribute__((weak))
int main()
{
    puts(myfunc());
}

v1(myfunc)
char const * v1_myfunc(void)
{
    return "v1_myfunc";
}

v2(myfunc)
char const * v2_myfunc(void)
{
    return "v2_myfunc";
}
