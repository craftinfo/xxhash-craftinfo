#! /usr/bin/env bash
#
#   Copyright (c) 2019 nat - ORGANIZATION
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of ORGANIZATION nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
[ "${TRACE}" = 'YES' -o "${MULLE_BUILD_SH_TRACE}" = 'YES' ] && set -x && : "$0" "$@"

#
# This is an example build script. Build scripts can be useful, if the
# project is based on make or some other non-mulle-make-supported build system.
#
# Rename it to build.sh and move it to the appropriate info directory folder,
# maybe <dependency>.linux, if its just applicable to linux.
#
# Enable it with:
#    mulle-sde dependency craftinfo --platform linux set <dependency> BUILD_SCRIPT build.sh
#
# Enable scripts with:
#    mulle-sde environment set MULLE_SDE_ALLOW_BUILD_SCRIPT 'YES'
#
# Hint: If this gets too complicated and you are tempted to massage the
#       Makefile, maybe it's easier to use the project embedded and compile
#       the sources yourself with cmake ?
#
MULLE_EXECUTABLE_VERSION=0.0.1


usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} [flags] [command] [options]

   Script to build xxhash.

Flags:
EOF

   options_technical_flags_usage "      : " >&2

   cat <<EOF >&2

Commands:
   install : build and install [default]
   build   : just build
   version : script version
EOF

   exit 1
}


clean_main()
{
   log_entry "clean_main" "$@"

   # get make to use KITCHEN_DIR (optional), PREFIX (maybe), CONFIGURATION, SDK
   #
   # Tips:
   #
   # set CFLAGS, LDFLAGS for CONFIGURATION (-DDEBUG ?)
   # set CFLAGS, LDFLAGS for SDK (darwin --isysroot)
   #
   exekutor make clean
}


build_main()
{
   log_entry "build_main" "$@"

   # get make to use KITCHEN_DIR (optional), PREFIX (maybe), CONFIGURATION, SDK
   #
   # Tips:
   #
   # set CFLAGS, LDFLAGS for CONFIGURATION (-DDEBUG ?)
   # set CFLAGS, LDFLAGS for SDK (darwin --isysroot)
   #
   logging_tee_eval_exekutor "${LOGFILE}" "${TEEFILE}" \
       make
}


install_main()
{
   log_entry "install_main" "$@"

   if ! build_main "$@"
   then
      return 1
   fi

   #
   # Collect results and place them into PREFIX if needed. F.e. the Makefile
   # does not support PREFIX.
   #
   # It's probably not a bad idea to use mulle-dispense for that.
   #
   # exekutor mulle-dispense dispense "${KITCHEN_DIR}" "${PREFIX}"
   #
   # But you could also just use a set of copy commands.
   #
   # exekutor mkdir -p "${PREFIX}/include/async"
   # exekutor cp async/async*.h "${PREFIX}/include/async"

   logging_tee_eval_exekutor "${LOGFILE}" "${TEEFILE}" \
      mkdir -p "${PREFIX}/include/xxhash" &&
   logging_tee_eval_exekutor "${LOGFILE}" "${TEEFILE}" \
      mkdir -p "${PREFIX}/lib" &&
   logging_tee_eval_exekutor "${LOGFILE}" "${TEEFILE}" \
      cp libxxhash.a "${PREFIX}/lib/" &&
   logging_tee_eval_exekutor "${LOGFILE}" "${TEEFILE}" \
      cp *.h "${PREFIX}/include/xxhash/"
}


main()
{
   local CONFIGURATION="Debug"
   local SDK=""
   local PREFIX="/tmp"
   local KITCHEN_DIR="kitchen"
   local LOGFILE
   local TEEFILE

   while [ "$#" -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -h*|--help|help)
            usage
         ;;

         --sdk)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            SDK="$1"
         ;;

         --configuration)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            CONFIGURATION="$1"
         ;;

         --kitchen-dir|--build-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            KITCHEN_DIR="$1"
         ;;

         --logfile)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            LOGFILE="$1"
         ;;

         --teefile)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            TEEFILE="$1"
         ;;

         --platform)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            PLATFORM="$1"
         ;;

         --prefix|--install-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            PREFIX="$1"
         ;;

         -*)
            usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}"

   if [ -z "${TEEFILE}" ]
   then
      if [ "${MULLE_FLAG_LOG_VERBOSE}" ]
      then
         TEEFILE="/dev/stderr"
      else
         TEEFILE="/dev/null"
      fi
   fi

   if [ -z "${LOGFILE}" ]
   then
      LOGFILE="/dev/null"
   fi

   # see with -ls
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "CONFIGURATION = \"${CONFIGURATION}\""
      log_trace2 "KITCHEN_DIR   = \"${KITCHEN_DIR}\""
      log_trace2 "PLATFORM      = \"${PLATFORM}\""
      log_trace2 "PREFIX        = \"${PREFIX}\""
      log_trace2 "PWD           = \"${PWD}\""
      log_trace2 "SDK           = \"${SDK}\""
      log_trace2 "TEEFILE       = \"${TEEFILE}\""
      log_trace2 "LOGFILE       = \"${LOGFILE}\""
   fi

   local cmd

   cmd="${1:-install}"

   case "${cmd}" in
      build|clean|install)
         ${cmd}_main "$@"
      ;;

      *)
         usage "Unknown command \"${cmd}\""
      ;;
   esac
}


########
###
### INIT
###
_init()
{
   #
   # minimal setup exit
   #
   if [ "$1" = "version" ]
   then
      printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
      exit 0
   fi

   if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ]
   then
      MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env libexec-dir 2> /dev/null`"
      if [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ]
      then
         if [ -z "`command -v "mulle-bashfunctions-env"`" ]
         then
            echo "Fatal Error: Could not find mulle-bashfunctions-env in PATH (not installed ?)" >&2
         else
            echo "Fatal Error: Could not find libexec of mulle-bashfunctions-env ($PWD)" >&2
         fi
         exit 1
      fi
   fi

      # shellcheck source=../mulle-bashfunctions/src/mulle-string.sh
   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" ||
      fail "failed to load bashfunctions from ${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}"

   set -o pipefail
}
###
### INIT
###
########


#
# leading backslash ? looks like we're getting called from
# mingw via a .BAT or so
#
case "$PATH" in
   '\\'*)
      PATH="${PATH//\\/\/}"
   ;;
esac


_init "$@" # needs params
main "$@"
