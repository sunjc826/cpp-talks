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
    struct __attribute__((abi_tag("v1"))) String {
        char const * c_str;
        String(char const *c_str) : c_str(c_str) {}
    };
}

v2_inline namespace v2 
{
    struct __attribute__((abi_tag("v2"))) String {
        size_t strlen;
        char const * c_str;
        String(char const *c_str) : strlen(std::strlen(c_str)), c_str(c_str) {}
    };
    
}
String myfunc()
{
    #if CURRENT_VERSION == 1
    return "v1_myfunc";
    #else
    return "v2_myfunc";
    #endif
}

__attribute__((weak))
int main()
{
    String s = myfunc();
    puts(s.c_str);
}
