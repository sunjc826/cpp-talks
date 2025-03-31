#!/usr/bin/env bash
log_err()
{
    printf >&2 "$(tput setaf 1)ERROR: %s$(tput sgr0)\n" "$*"
}

log_and_run()
{
    printf >&2 "$(tput bold)(bash)\$$(tput sgr0) %s\n" "$*"
    "$@"
}

section_marker()
{
    printf "$(tput bold)---%s---$(tput sgr0)\n" "$*"
}

function __compile_main()
{
    set -o pipefail
    local cc=gcc
    local is_compile_as_lib=false
    local version=
    local is_swap_executable_version=false
    local file=
    local is_execute=false
    local is_show_symbols=false
    local is_completion=false
    local is_cpp_filt=true
    if (("${#COMP_WORDS[@]}" == 0))
    then
        local autocompletion=() autocompletion_lazy=()
    fi
    local is_help=false
    local shift_by
    while (( $# > 0 ))
    do
        shift_by=1
        autocompletion=()
        autocompletion_lazy=(sed -rn 's/ *(--[[:alnum:]][[:alnum:]-]*)\) */\1/p' "${BASH_SOURCE[0]}")
        case "$1" in
        --cc)
            autocompletion=(gcc clang)
            autocompletion_lazy=()
            cc=$2
            shift_by=2
            ;;
        --compile-as-lib)
            is_compile_as_lib=true
            ;;
        --version)
            autocompletion=({1..2})
            autocompletion_lazy=()
            version=$2
            shift_by=2
            ;;
        --swap-executable-version)
            is_swap_executable_version=true
            ;;
        --file)
            autocompletion_lazy=(find . '(' -name '*.c' -o -name '*.cpp' ')' -printf "%P\n")
            file=$2
            shift_by=2
            ;;
        --execute)
            is_execute=true
            ;;
        --show-symbols)
            is_show_symbols=true
            ;;
        --no-cppfilt)
            is_cpp_filt=false
            ;;
        --completion)
            is_completion=true
            ;;
        *)
            is_help=true
            err_msg="Unrecognized argument $1"
            break
            ;;
        esac
        if (( shift_by > $# ))
        then
            is_help=true
            err_msg="Expected $((shift_by+1)) arguments for $1"
            break
        fi
        shift "$shift_by"
    done

    if "$is_completion"
    then
    cat <<EOF
__compile_complete()
{
    local command=\$1 cur_word=\$2 prev_word=\$3
    local autocompletion=() autocompletion_lazy=()
    if ! command -v "\$command" &>/dev/null;
    then
        return
    fi    
    source "\${COMP_WORDS[@]:0:COMP_CWORD}" ""
    COMPREPLY=(\$(compgen -W "\${autocompletion[*]} \$("\${autocompletion_lazy[@]}")" -- "\$cur_word"))
}
complete -F __compile_complete compile.sh
complete -F __compile_complete ./compile.sh
EOF
        return 0
    fi

    if (("${#COMP_WORDS[@]}" > 0))
    then
        return 0
    fi

    if "$is_help"
    then
        local ret=0
        if [[ -n "$err_msg" ]]
        then 
            printf "%s\n" "$err_msg"
            ret=1
        fi
        return "$ret"
    fi

    if [[ ! -e "$file" ]]
    then
        echo "$file doesn't exist" >&2
        return 1
    fi

    local is_cpp;
    case "$file" in
    *.c)
        is_cpp=false
    ;;
    *.cpp)
        is_cpp=true
    ;;
    *)
        log_err "Unrecognized extension .${file##*.}"
        return 1
        ;;
    esac

    case "$cc" in
    clang)
        if "$is_cpp"
        then
            cc=clang++
        fi
        ;;
    gcc)
        if "$is_cpp"
        then
            cc=g++
        fi
        ;;
    esac

    if ! command -v "$cc" &>/dev/null
    then
        log_err "compiler $cc not found"
        return 1
    fi

    local file_dirname=
    local file_basename=
    case "$file" in
    */*)
        file_dirname=${file%/*}
        file_basename=${file##*/}
        ;;
    *)
        file_dirname=.
        file_basename=$file
        ;;
    esac

    local out
    local cc_args=()
    if "$is_compile_as_lib"
    then
        section_marker "Compiling and linking into shared library"
        out=${file_dirname}/lib${file_basename%.*}.so
        cc_args=(-shared)
        if [[ -e "${file%.*}.ver" ]]
        then
            cc_args+=("-Wl,--version-script=${file%.*}.ver")
        fi
    else
        section_marker "Compiling and linking into executable"
        out="${file%.*}.exe"
    fi
    if ! log_and_run "$cc" -o "$out" -DCURRENT_VERSION="$version" --save-temps "${cc_args[@]}" "$file"
    then
        log_err "compilation failed"
        return 1
    fi
    if "$is_execute"
    then
        local runnable=$out
        if "$is_compile_as_lib"
        then
            section_marker "Linking shared library $out before we can run it"
            runnable="${file%.*}.exe"
            local opt_main=()
            if [[ -e "${file%.*}_main.${file##*.}" ]]
            then
                echo "We also found a 'main' file (this should provide a main function)"
                opt_main=("${file%.*}_main.${file##*.}")
                local executable_version=$version
                if "$is_swap_executable_version"
                then
                    case "$version" in
                    1) executable_version=2;;
                    2) executable_version=1;;
                    *) log_err "This should not be reached"; return 1;;
                    esac
                    echo "The executable will be (purposely) compiled with the wrong CURRENT_VERSION $executable_version"
                fi
                opt_main+=(-DCURRENT_VERSION="$executable_version")
            fi

            if ! log_and_run "$cc" -o "$runnable" --save-temps -Wl,-rpath="$(dirname -- "$out")" "$out" "${opt_main[@]}"
            then
                log_err "Linking failed"
                return 1
            fi
        fi
        section_marker "Executing the executable $runnable (Output in green)"
        tput setaf 2
        if ! ./"$runnable"
        then
            tput sgr0
            log_err "$runnable failed"
            return 1
        fi
        tput sgr0
    fi
    if "$is_show_symbols"
    then
        section_marker "Printing relevant entries from the symbol table"
        if ! { log_and_run readelf --wide --syms "$out" |\
             grep -E '(^Symbol table)|myfunc' |\
             if "$is_cpp" && "$is_cpp_filt"; then c++filt; else cat ;fi ;}
        then
            log_err "readelf failed"
        fi

        section_marker "Printing symbol version info"
        if ! log_and_run readelf --wide --version-info "$out"
        then
            log_err "readelf failed"
        fi
    fi
}

__compile_main "$@"
