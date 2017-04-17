# Common definitions for CASS (course admin shell scripts).

find_course_root () {
    cd "$(dirname $0)"

    while ! [ -f .root ]; do
        if [ $(pwd) = / ]; then
            echo >&2 Could not find course root
            exit 3
        fi
        cd ..
    done

    pwd
}

COURSE_ROOT="$(find_course_root)" || exit 3
COURSE_BIN="$COURSE_ROOT/bin"
COURSE_LIB="$COURSE_ROOT/lib"
COURSE_ETC="$COURSE_ROOT/etc"
export COURSE_ROOT COURSE_BIN COURSE_LIB COURSE_ETC

. "$COURSE_ETC/config.sh"

course_use () {
    local each
    for each; do
        . "$COURSE_LIB/$each.sh"
    done
}

locate_grade () {
    local hw="$1"
    local netid="$2"
    echo "$COURSE_DB/grades/$netid/$hw"
}

locate_grade_dir () {
    local netid="$1"
    echo "$COURSE_DB/grades/$netid"
}

getargs () {
    (
    usage='Usage: eval "$(getargs [-OPTS] ARGNAME... [...])"'
    case "$1" in
        --help|'')
            echo "$usage"
            return 0
            ;;
        -*)
            flags="$(echo $1 | sed 's/^-//')"
            shift;
            ;;
    esac

    if [ -n "$flags" ]; then
        printf 'args=`getopt %s $*`\n' $flags
        echo 'if [ $? != 0 ]; then'
        printf '    echo>&2 "Usage: $0 -%s ' $flags
        printf '%s"\n' "$*" | tr a-z A-Z
        echo '    exit 2'
        echo 'fi'
        echo 'set -- $args'

        echo 'while [ -n "$1" ]; do'
        echo '    case "$1" in'
        for flag in $(echo $flags | sed 's/./& /g'); do
            printf '        -%s) flag_%s=-%s; shift;;\n' $flag $flag $flag
        done
        echo '        --) shift; break;;'
        echo '    esac'
        echo 'done'
    fi

    for arg; do
        if [ "$arg" = ... ]; then
            etc='-z not-z'
            break
        else
            etc='-n "$*"'
        fi

        printf '%s="$1"; shift\n' $arg
    done

    printf 'if [ %s' "$etc"
    for arg; do
        printf ' -o -z "$%s"' $arg
    done
    printf ' ]; then\n'
    printf '    echo>&2 "Usage: $0 '
    if [ -n "$flags" ]; then
        printf '%s%s ' - "$flags"
    fi
    printf '%s"\n' "$*" | tr a-z A-Z
    printf '    exit 2\nfi\n'

    )
}

team_members () {
    echo "$*" | sed 's/-/ /g'
}

find_single_matching () {
    local description
    local pattern
    eval "$(getargs description pattern ...)"

    local candidates
    candidates="$("$@" | egrep "$pattern")"

    if [ $(echo "$candidates" | wc -w) = 1 ]; then
        echo "$candidates"
    else
        echo "Cannot resolve $description" >&2
        echo "Candidates were:"                      >&2
        echo "$candidates" | tr '\n' ' ' | fmt        >&2
        exit 2
    fi
}

resolve_student () {
    local pattern
    eval "$(getargs pattern)"

    find_single_matching "student: $pattern" "^$pattern" \
        "$COURSE_BIN/all_students.sh"
}

resolve_team () {
    local hw
    local pattern
    eval "$(getargs hw pattern)"

    find_single_matching "team: $pattern" "\\<$pattern" \
            "$COURSE_BIN/all_teams.sh" $hw
}
