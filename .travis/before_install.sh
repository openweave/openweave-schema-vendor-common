#!/bin/sh

#
#    Copyright 2018-2019 Google LLC All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

#
#    Description:
#      This file is the script for Travis CI hosted, distributed continuous 
#      integration 'before_install' trigger of the 'install' step.
#

die()
{
    echo " *** ERROR: " ${*}
    exit 1
}

#
# installdeps <dependency tag>
#
# Abstraction for handling common dependency fulfillment across
# different, but related, test targets.
#
installdeps()
{
    case "${1}" in

        openweave-wdlc)
            # Clone the latest commit of WDLC from Github.

            cd ${HOME}
            git clone https://github.com/openweave/openweave-wdlc.git
            cd ${HOME}/openweave-wdlc

            # First, satisfy any protobuf dependencies.

            sudo contrib/download_protoc.sh

            # Finally, configure and install wdlc itself.

            ./configure && make && sudo make install
 

            ;;
        
    esac
}

# Package build machine OS-specific configuration and setup

case "${TRAVIS_OS_NAME}" in

    linux)
        # Satisfy WDLC Python-specific dependencies.

        sudo apt-get update
        sudo apt-get install python2.7 python-pip python-virtualenv

        # Install WDLC and any remaining depedencies.

        installdeps "openweave-wdlc"

        ;;

    osx)
        # Satisfy WDLC Python-specific dependencies.

        easy_install pip

        # Using easy_install to setup virtualenv for some reason gives Github the fits - it starts failing installing some
        # of the dependent packages of virtualenv (zipp, see https://github.com/LibreTime/libretime/issues/952). Even putting
        # that workaround in isn't sufficient, as other failures ensue. Using pip seems to be the more modern way of setting up
        # virtualenv, so follow the masses if it ain't causing issues.
        pip install virtualenv

        # Install WDLC and any remaining depedencies.

        installdeps "openweave-wdlc"

        ;;


    *)
        die "Unknown OS name \"${TRAVIS_OS_NAME}\"."

        ;;

esac
