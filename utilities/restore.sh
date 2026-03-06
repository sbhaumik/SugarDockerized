#!/bin/bash

# Enrico Simonetti
# enricosimonetti.com

if [ -z $1 ]
then
    echo Provide the backup suffix as script parameters
else
    # check if the stack is running
    running=`docker ps | grep sugar-sqlserver | wc -l`

    # check if rsync is installed
    if [ `command -v rsync | grep rsync | wc -l` -eq 0 ]
    then
        echo Please install \"rsync\" before running the restore command
        exit 1
    fi

    if [ $running -gt 0 ]
    then
        # running

        # enter the repo's root directory
        REPO="$( dirname ${BASH_SOURCE[0]} )/../"
        cd $REPO

        BACKUP_DIR="backups/backup_$1"
        # check if the backup name has been provided including the backup_ prefix
        if [ ! -d $BACKUP_DIR ] && [ -d "backups/$1" ]
        then
            BACKUP_DIR="backups/$1"
        fi

        echo Restoring sugar from \"$BACKUP_DIR\"

        # if it is our repo, and the source exists, and the destination does not
        if [ -f '.gitignore' ] && [ -d 'data' ] && [ -d $BACKUP_DIR ] && [ -d $BACKUP_DIR/sugar ] && ( [ -f $BACKUP_DIR/sugar.bak ] || [ -f $BACKUP_DIR/sugar.bak.tgz ] )
        then
            if [ -d 'data/app/sugar' ]
            then
                rm -rf data/app/sugar
            fi
            echo Restoring application files
            sudo rsync -a $BACKUP_DIR/sugar data/app/
            echo Application files restored

            echo Restoring database
            docker exec -it sugar-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Sugar123!" -Q "IF DB_ID('sugar') IS NOT NULL DROP DATABASE [sugar]" -C
            docker exec -it sugar-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Sugar123!" -Q "CREATE DATABASE [sugar]" -C

            if [ -f $BACKUP_DIR/sugar.bak.tgz ]
            then
                if hash tar 2>/dev/null; then
                    tar -zxf $BACKUP_DIR/sugar.bak.tgz
                    echo Database backup uncompressed to $BACKUP_DIR/sugar.bak
                fi
            fi

            if [ -f $BACKUP_DIR/sugar.bak ]
            then
                docker cp $BACKUP_DIR/sugar.bak sugar-sqlserver:/tmp/sugar_backup.bak
                docker exec -it sugar-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Sugar123!" -Q "RESTORE DATABASE [sugar] FROM DISK = N'/tmp/sugar_backup.bak' WITH FILE = 1, REPLACE, NOUNLOAD, STATS = 5" -C
                echo Database restored
            else
                echo Database backup not found! The selected restore is corrupted
                exit 1
            fi

            if [ -f $BACKUP_DIR/sugar.bak.tgz ]
            then
                if [ -f $BACKUP_DIR/sugar.sql ]
                then
                    rm $BACKUP_DIR/sugar.sql
                fi
            fi

            # refresh all transient storages
            ./utilities/build/refreshsystem.sh

            echo Repairing system
            ./utilities/repair.sh
            echo System repaired

            echo Performing Elasticsearch re-index
            ./utilities/runcli.sh "./bin/sugarcrm search:silent_reindex"
            echo Restore completed!
        else
            if [ ! -d 'data' ]
            then
                echo \"data\" cannot be empty, the command needs to be executed from within the clone of the repository
            fi

            if [ ! -d $BACKUP_DIR/sugar ]
            then
                echo \"$BACKUP_DIR/sugar\" cannot be empty
            fi

            if [ ! -f $BACKUP_DIR/sugar.sql ]
            then
                echo \"$BACKUP_DIR/sugar.sql\" does not exist
            fi

            if [ ! -d $BACKUP_DIR ]
            then
                echo $BACKUP_DIR does not exist
            fi
        fi

    else
        echo The stack is not running, please start the stack first
    fi
fi
