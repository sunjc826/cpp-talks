#include "utils.hpp"
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

int main()
{
#if CURRENT_VERSION == 1
    using namespace v1;
#elif CURRENT_VERSION == 2
    using namespace v2;
#else
#   error "Bad CURRENT_VERSION"
#endif
    
    puts(myfunc());
}
