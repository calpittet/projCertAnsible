#!/bin/bash

echo "Begin Chrome Driver install script."

if [ -z $SERVICE_USER -a -z $SERVICE_GROUP ]; then
    # On maestro deploy, user should be specified with RUN_USER
    # On domo vm deploy, user should be specified by SERVICE_USER
    SERVICE_USER=$RUN_USER
    SERVICE_GROUP=$RUN_USER
fi

CHROME_ZIP="chromedriver_linux64.zip"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "Detected Linux operating system"
    CHROME_ZIP="chromedriver_linux64.zip"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected OS X operating system"
    CHROME_ZIP="chromedriver_mac32.zip"
else
    echo "ERROR: Unsupported operating system for DaVinci's Chrome Driver. Exiting now."
    exit 1
fi

CHROME_DRIVER="chromedriver"
CHROME_DRIVER_VERSION="2.19"
CHROME_DRIVER_URL="http://chromedriver.storage.googleapis.com/${CHROME_DRIVER_VERSION}/${CHROME_ZIP}"

echo "Checking for Selenium Chrome driver at ./${CHROME_DRIVER}"
if [ -f $CHROME_DRIVER ] ; then
    echo "Chrome driver already installed."
else
    TRIES=0
    while [ $TRIES -lt 5 -a ! -f $CHROME_DRIVER ]; do
        echo "Attempt $TRIES at downloading Selenium Chrome driver from ${CHROME_DRIVER_URL}"
        if curl -O $CHROME_DRIVER_URL ; then
            if file $CHROME_ZIP | grep "Zip archive data"; then
                echo "Download successful."
                echo "Unzipping $CHROME_ZIP"
                if unzip $CHROME_ZIP ; then
                    echo "$CHROME_ZIP unzipped successfully"
                    if [ -f $CHROME_DRIVER ] ; then
                        echo "Chrome driver unzipped and $CHROME_DRIVER located."
                        echo "Setting $CHROME_DRIVER ownership to ${SERVICE_USER}:${SERVICE_GROUP}"
                        chown ${SERVICE_USER}:${SERVICE_GROUP} $CHROME_DRIVER
                    else
                        echo "ERROR: Chrome driver unzipped successfully but unable to locate ${CHROME_DRIVER}."
                    fi
                else
                    echo "ERROR: Unzip of Chrome driver failed."
                fi
            else
                echo "Download unsuccessful. $CHROME_ZIP is not a zip archive."
            fi
        else
            echo "ERROR: Download of Selenium Chrome driver failed. Failing prematurely."
            exit 1
        fi
        if [ ! -f $CHROME_DRIVER ] ; then
            ((TRIES++))
            SLEEP=$(($TRIES * 30))
            echo "Failed to install Chrome driver. Sleeping for $SLEEP seconds then trying again."
            sleep $SLEEP
        fi
    done
    if [ -f $CHROME_ZIP ] ; then
        echo "Cleaning up $CHROME_ZIP"
        rm $CHROME_ZIP
    fi
    if [ -f $CHROME_DRIVER ] ; then
        echo "Chrome driver installed successfully!"
    else
        echo "ERROR: Unable to install Chrome driver, service has failed to start. Exiting now."
        exit 1
    fi
fi

