#!/usr/bin/env bash
set -e

__fontBold=$(tput bold)
__fontNormal=$(tput sgr0)
__separator='--------------------------------------------------'

################################################################################
# Return the arguments in bold format
# Globals:
#     __fontBold
#     __fontNormal
# Arguments:
#     $@: Values to print
# Returns:
#     Values in bold format
################################################################################
function bold() {
    printf "${__fontBold}%s${__fontNormal}" "${@}"
}

__lib='logger'
__version='0.1.0'
__usage="
$(bold 'NAME')
        $__lib - build script

$(bold 'SYNOPSIS')
        $(bold $0) [OPTION...] [ARGUMENT...]

$(bold 'DESCRIPTION')
        This is the build script for $(bold $__lib).

$(bold 'OPTIONS')
    $(bold 'Generic Program Information')
        $(bold '--help') Output a usage message and exit.

        $(bold '-V, --version')
            Output the version number of the library and exit.

    $(bold 'Generic Output Control')
        $(bold '-v, --verbose')
            Enable verbose mode.

        $(bold '-d, --debug')
            Enable debug mode.

    $(bold 'Enviroment Control')
        $(bold '--clean')   Clean the enviroment and exit.

        $(bold '--dry')   Clean the enviroment before the build.

$(bold 'USAGE')
    $(bold 'Include')
        Include the library in your source file:

        | $(bold '<> main.cpp')
        | #include \"path/to/lib/$__lib.hpp\"
        | ...

        Link the object file:

        | $(bold '<> bash')
        | g++ ... path/to/lib/$__lib.a

    $(bold 'API')
        enum class LogLevel {
            Debug,
            Info,
            Warning,
            Error
        };
            Defines logging severity levels.

        struct Report final {
            uint line  = 0;
            uint start = 0;
            uint count = 0;
            LogLevel level = LogLevel::Debug;
            const char* message = \"\";
        };
    Type defining the message to log.
"

if (($# == 0)); then
    echo "${__usage}"
    exit 0
fi

args=$(getopt \
    -n $__lib \
    -o 'Vdvr' \
    -l 'help,version,verbose,debug,clean,dry' \
    -- "${@}")

if (($? != 0)); then
    echo 'Cannot parse arguments.'
    exit 1
fi

declare -A options=(
    [verbose]=false
    [debug]=false
    [clean]=false
    [args]=''
)

declare -A envFolders=(
    [src]='./src'
    [obj]='./obj'
    [bin]='./bin'
)

################################################################################
# Clean the enviroment
# Globals:
#     options
#     envFolders
################################################################################
function clean() {
    if [[ ${options[verbose]} = true ]]; then
        echo $(bold 'Cleaning Enviroment')
        echo "    $(bold 'Build Folders')"
    fi

    for key in ${!envFolders[@]}; do
        [[ $key = 'src' ]] && continue

        [[ ${options[verbose]} = true ]] && printf '        .%-5s = %s' $key ${envFolders[$key]}
        if [[ -d ${envFolders[$key]} ]]; then
            rm -r ${envFolders[$key]}
        else
            echo -n ' (skipped)'
        fi; echo ''
    done
}

################################################################################
# Compile source files and link object files
# Globals:
#     options
#     envFolders
################################################################################
function build() {
    # build object files
    [[ ${options[verbose]} = true ]] && echo $(bold 'Building Object Files')

    for file in $(find ${envFolders[src]} -type f -name "*.cpp" | sort); do
        local filename=$(basename $file)
        filename=${filename%%.*}
        
        local target="${envFolders[obj]}/$filename.o"
        local cmd=$(printf "${options[cmd.build]}" $target $file)

        # recompile if edited
        local fileTimestamp=$(stat -c %Y $file)
        local targetTimestamp=$([[ -f $target ]] \
            && stat -c %Y $target \
            || echo 0)

        if (($fileTimestamp > $targetTimestamp)); then
            [[ ${options[verbose]} = true ]] && printf '    %-20s -> %s\n' $file $target
            $cmd
        else
            [[ ${options[verbose]} = true ]] && printf '    %-20s -> (skipped)\n' $file
        fi
    done; [[ ${options[verbose]} = true ]] && echo ''

    # link object files
    if [[ ${options[verbose]} = true ]]; then 
        echo $(bold 'Linking Object Files')
        printf '    %-20s -> %s\n\n' "${envFolders[obj]}/*.o" "${envFolders[bin]}/$__lib.a"
    fi

    ${options[cmd.link]}
}

eval set -- ${args}
while true; do
    case $1 in
        # generic library information
        '--help')           echo "${__usage}"; exit 0 ;;
        '-V' | '--version') echo $__version;   exit 0 ;;

        # generic output control
        '-v' | '--verbose') options[verbose]=true; shift ;;
        '-d' | '--debug')   options[debug]=true;   shift ;;

        # enviroment control
        '--clean') clean; exit 0 ;;
        '--dry')        options[clean]=true; shift ;;
        
        # other
        '--') shift; break ;;
        *) echo "Option '$1' is not supported yet."; exit 1 ;;
    esac
done

if [[ (($# > 0)) && ${options[run]} = false ]]; then
    echo "Unsupported argument '${@}'."
    exit 1
else
    options[args]="${@}"
fi

# set build command
options[cmd.build]='g++ -Wall -Wextra -std=c++23 '

options[cmd.build]+=$([[ ${options[debug]} = true ]] \
    && options[cmd.build]+='-ggdb' \
    || options[cmd.build]+='-O2')

options[cmd.build]+=" -c -fPIC -o %s %s"

# set link command
options[cmd.link]="ar rvs -o ${envFolders[bin]}/$__lib.a ${envFolders[obj]}/*.o"

# print generic library information
if [[ ${options[verbose]} = true ]]; then
    echo $__separator
    echo "$(bold 'Build started') - $(date '+%d/%m/%Y %H:%M:%S')"
    echo $__separator
    echo $(bold 'Generic Program Information')
    echo "    $(bold 'Program')   $__lib"
    echo "    $(bold 'Version')   $__version"
    echo "    $(bold 'Options')"
    for key in ${!options[@]}; do
        printf '        .%-10s = %s\n' $key "${options[$key]}"
    done | sort -k 2n
    echo ''
fi

# clean enviroment
[[ ${options[clean]} = true ]] && clean

# initialise enviroment
if [[ ${options[verbose]} = true ]]; then
    echo ''
    echo $(bold 'Initialising Enviroment')
    echo "    $(bold 'Build Folders')"
fi

for key in ${!envFolders[@]}; do
    [[ $key = 'src' ]] && continue

    [[ ${options[verbose]} = true ]] && printf '        .%-5s = %s\n' $key ${envFolders[$key]}
    mkdir -p ${envFolders[$key]}
done; [[ ${options[verbose]} = true ]] && echo ''

# ensure source folder
if [[ ${options[verbose]} = true ]]; then
    echo "    $(bold 'Source Folder')"
    printf '        .%-5s = %s\n\n' 'src' ${envFolders[src]}
fi

if [[ ! -d ${envFolders[src]} ]]; then
    echo "Cannot find source folder '${envFolders[src]}'."
    exit 1
fi

# time build time
timeStart=$(date '+%s.%N')

build

timeEnd=$(date '+%s.%N')
elapsed=$(echo "$timeEnd - $timeStart" | bc -l | sed -r 's/(.*\..{3}).*/\1/')

if [[ ${options[verbose]} = true ]]; then
    echo $__separator
    echo "$(bold 'Build completed') - $(date '+%d/%m/%Y %H:%M:%S') (${elapsed}s)"
    echo 'Copying headers ...'
    echo $__separator
fi

# copy headers
cp $(find ${envFolders[src]} -type f -name "*.hpp") -- ${envFolders[bin]}
