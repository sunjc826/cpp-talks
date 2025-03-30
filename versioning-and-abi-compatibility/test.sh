#!/usr/bin/env bash
pushd "$(dirname -- "${BASH_SOURCE[0]}")"
function __test_main()
{
    local source_files=()
    mapfile -t source_files < <(find ./ -name "*.c" -o -name "*.cpp" | grep --invert-match "_main")
    local version
    local source_file
    for version in {1..2}; do
    for source_file in "${source_files[@]}"; do
    for compile_as_lib in '' '--compile-as-lib'; do
        local opt_compile_as_lib=($compile_as_lib)
        if ! ./compile.sh --file "$source_file" --version "$version" --execute "${opt_compile_as_lib[@]}"
        then
            echo Failed!
            return 1
        fi
    done
    done
    done

    for version in {1..2}
    do
        if ! ./compile.sh --file no_abi_tag.cpp --version 2 --execute --compile-as-lib --swap-executable-version 2>&1 >/dev/null | grep "Segmentation fault"
        then
            echo "Warn: Somewhat surprising: we didn't see a segfault"
        else
            echo "This segfault is to be expected"
        fi
    done
    echo Success!
}
__test_main
popd