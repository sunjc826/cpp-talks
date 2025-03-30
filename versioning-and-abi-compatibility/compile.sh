log_err()
{
    printf >&2 "ERROR: %s\n" "$*"
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
    local cc=g++
    local is_compile_as_lib=false
    local version=
    local file=
    local is_execute=false
    local is_show_symbols=false
    local is_completion=false
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
        --file)
            autocompletion_lazy=(compgen -f)
            file=$2
            shift_by=2
            ;;
        --execute)
            is_execute=true
            ;;
        --show-symbols)
            is_show_symbols=true
            ;;
        --completion)
            is_completion=true
            ;;
        *)
            is_help=true
            err_msg="Unrecognized argument $1"
            ;;
        esac
        if (( shift_by > $# ))
        then
            is_help=true
            err_msg="Expected $shift_by+1 arguments for $1"
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
    source "\${COMP_WORDS[@]:0:COMP_CWORD+1}" || true
    COMPREPLY=(\$(compgen -W "\${autocompletion[*]} \$("\${autocompletion_lazy[@]}")" -- "\$cur_word"))
}
complete -F __compile_complete compile.sh
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
    local out
    local cc_args=()
    if "$is_compile_as_lib"
    then
        section_marker "Compiling and linking into shared library"
        out="lib${file%.*}.so"
        cc_args=(-shared)
        if [[ -e "${file%.*}.ver" ]]
        then
            cc_args+=("-Wl,--version-script=${file%.*}.ver")
        fi
    else
        section_marker "Compiling and linking into executable"
        out="${file%.*}.exe"
    fi
    if ! log_and_run "$cc" -o "$out" -DCURRENT_VERSION="$version" "${cc_args[@]}" "$file"
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
            if ! log_and_run "$cc" -o "$runnable" -Wl,-rpath="$(dirname -- "$out")" "$out"
            then
                log_err "Linking failed"
            fi
        fi
        section_marker "Executing the executable $runnable"
        if ! log_and_run "$runnable"
        then
            log_err "$runnable failed"
        fi
    fi
    if "$is_show_symbols"
    then
        section_marker "Printing relevant entries from the symbol table"
        if ! { log_and_run readelf --wide --syms "$out" |\
             grep -E '(^Symbol table)|myfunc' |\
             if "$is_cpp"; then c++filt; else cat ;fi ;}
        then
            log_err "readelf failed"
        fi

        section_marker "Printing symbol version info"
        log_and_run readelf --wide --version-info "$out"
    fi
}

__compile_main "$@"
