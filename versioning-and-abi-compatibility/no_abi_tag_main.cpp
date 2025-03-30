#include "utils.hpp"
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
#   error "Bad CURRENT_VERSION"
#endif

v1_inline namespace v1
{
    struct String {
        char const * c_str;
        String(char const *c_str) : c_str(c_str) {}
    };
}

v2_inline namespace v2
{
    struct String {
        size_t strlen;
        char const * c_str;
        String(char const *c_str) : strlen(std::strlen(c_str)), c_str(c_str) {}
    };
}

String myfunc();
int main()
{
    String s = myfunc();
    puts("We are in abi_tag_main");
    puts(s.c_str);
}