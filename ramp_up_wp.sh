#!/bin/bash
function ramp_up_wp() {
    # Read config file
    source ./ramp_up_wp.config

    echo "Welcome to the wordpress ramp-up installer"
    echo

    # Ask user where to create the project
    if [ -z "$projectsFolder" ]; then
        read -p "Do you store your projects in ~/Sites ? (y/n) " -r
        if [[ $REPLY =~ ^[Nn]$ ]]
        then
            read -p "Okay then. Enter your projects folder: " projectsFolder
        else
            projectsFolder="~/Sites"
        fi
    fi
    # Replace tilde with home var
    projectsFolderWithTilde=${projectsFolder/$HOME/\~}
    projectsFolder=${projectsFolder/\~/$HOME}

    if [ -z "$wordpressProjectsFolder" ]; then
        read -p "Do you store your wordpress projects in $projectsFolderWithTilde/wordpress ? (y/n) " -r
        if [[ $REPLY =~ ^[Nn]$ ]]
        then
            read -p "Okay then. Enter your wordpress projects folder: " wordpressProjectsFolder
        else
            wordpressProjectsFolder="~/Sites/wordpress"
        fi
    fi
    # Replace tilde with home var
    wordpressProjectsFolderWithTilde=${wordpressProjectsFolder/$HOME/\~}
    wordpressProjectsFolder=${wordpressProjectsFolder/\~/$HOME}

    if [ -z "$projectName" ]; then
        read -p "What's the name of the project ? " projectName
    fi

    projectLocation=$wordpressProjectsFolder/$projectName
    projectLocationWithTilde=$wordpressProjectsFolderWithTilde/$projectName
    projectLocationWithTilde=${projectLocationWithTilde/$HOME/\~}
    echo "Creating project folder at $projectLocationWithTilde..."
    mkdir -p $projectLocation
    echo "Done."
    echo "The project folder is: $projectLocationWithTilde"

    # Download wordpress
    wordpressLocation=$projectLocation/latest.tar.gz
    echo "Downloading wordpress..."
    wget -qO $wordpressLocation "wordpress.org/latest.tar.gz"
    echo "Extracting wordpress..."
    tar xzf $wordpressLocation -C $projectLocation
    echo "Removing wordpress archive..."
    rm -rf "${wordpressLocation}"
    mv $projectLocation/wordpress/* $projectLocation/
    rm -rf $projectLocation/wordpress
    wordpressLocation=$projectLocation/

    echo "The database for the project will be created with the name ${projectName}_wp"
    if [ -z "$mysqlUser" ] && [ -z "$mysqlPass" ];then
        echo "Now you'll have to login into mysql"
        local mysqlUser mysqlPass
        read -e -p "user: " mysqlUser
        read -e -s -p "pass: " mysqlPass
        echo
    fi
    mysql -u$mysqlUser -p$mysqlPass -e "DROP DATABASE ${projectName}_wp;"
    mysql -u$mysqlUser -p$mysqlPass -e "CREATE DATABASE ${projectName}_wp;"

    # Ask user for database file
    if [ -z "$hasDatabase" ]; then
        read -p "Do you have a database file ? (y/n) " hasDatabase
        if [[ $hasDatabase =~ ^[Yy]$ ]]; then
            # Prompt user for location
            if [ -z $databaseLocation ]; then
                read -e -p "Okay then. Give me the location of it: " databaseLocation
            fi
            databaseLocation=${databaseLocation/\~/$HOME}
            mysql -u $mysqlUser -p$mysqlPass "$projectName_wp" < $databaseLocation
        else
            echo "No problem. It will be automatically created by wordpress."
        fi
    fi

    # Ask user for wp-config
    if [ -z "$hasWpConfig" ]; then
        read -p "Do you have a custom wp-config file ? (y/n) " hasWpConfig
        if [[ $hasWpConfig =~ ^[Yy]$ ]]; then
            read -e -p "Ok then. Give me the location of it: " wpConfigLocation
            wpConfigLocation=${wpConfigLocation/\~/$HOME}
            rm -rf $projectLocation/wp-config.php
            ln -s $wpConfigLocation $projectLocation/wp-config.php
            wpConfigLocation=$projectLocation/wp-config.php
            sed -i "s/define('DB_NAME', '\(.*\)');/define('DB_NAME', '$projectName_wp');/g" $wpConfigLocation
            sed -i "s/define('DB_USER', '\(.*\)');/define('DB_USER', '$mysqlUser');/g" $wpConfigLocation
            sed -i "s/define('DB_PASSWORD', '\(.*\)');/define('DB_PASSWORD', '$mysqlPass');/g" $wpConfigLocation
        else
            echo "No problem. It will be automatically created by wordpress."
        fi
    fi

    # Ask user for .htaccess
    if [ -z "$hasHtaccess" ]; then
        read -p "Do you have a custom .htaccess file ? (y/n) " hasHtaccess
        if [[ $hasHtaccess =~ ^[Yy]$ ]]; then
            read -e -p "Ok then. Give me the location of it: " htaccessLocation
            htaccessLocation=${htaccessLocation/\~/$HOME}
            rm -rf $projectLocation/.htaccess
            ln -s $htaccessLocation $projectLocation/.htaccess
            htaccessLocation=$projectLocation/.htaccess
        else
            echo "No problem, it will be automatically created by wordpress."
        fi
    fi
}
ramp_up_wp
