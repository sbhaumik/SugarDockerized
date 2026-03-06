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
        echo Please install \"rsync\" before running the backup command
        exit 1
    fi

    if [ $running -gt 0 ]
    then
        # running

        # enter the repo's root directory
        REPO="$( dirname ${BASH_SOURCE[0]} )/../"
        cd $REPO

        BACKUP_DIR="backups/backup_$1"
        echo Backing up sugar to \"$BACKUP_DIR\"

        # if it is our repo, and the source exists, and the destination does not
        if [ -f '.gitignore' ] && [ -d 'data' ] && [ ! -d $BACKUP_DIR ] && [ -d 'data/app/sugar'  ]
        then

            # checking db name if it is indeed sugar
            DB_NAME=`cat data/app/sugar/config.php | grep db_name | awk '{print $3}' | sed 's/[^[:alnum:]]//g'`

            if [ $DB_NAME == 'sugar' ]
            then
                mkdir -p $BACKUP_DIR
                sudo rsync -a data/app/sugar $BACKUP_DIR/
                if [ -d $BACKUP_DIR/sugar ]
                then
                    echo Application files backed up on $BACKUP_DIR/sugar
                else
                    echo Application files NOT backed up!!!
                    echo Please discard the current backup
                fi
                #sqlcmd backup script for SQL Server instead
                # running sqlcmd backup on the sqlserver container instead
                docker exec -it sugar-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Sugar123!" -Q "BACKUP DATABASE [sugar] TO DISK = N'/tmp/sugar_backup.bak' WITH FORMAT, INIT, NAME = 'sugar-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10" -C
                docker cp sugar-sqlserver:/tmp/sugar_backup.bak $BACKUP_DIR/sugar.bak

                if [ \( -f $BACKUP_DIR/sugar.bak \) -a \( "$?" -eq 0 \) ]
                then
                    echo Database backed up on $BACKUP_DIR/sugar.bak
                    if hash tar 2>/dev/null; then
                        tar -zcvf $BACKUP_DIR/sugar.bak.tgz $BACKUP_DIR/sugar.bak
                    fi
                    if [ -f $BACKUP_DIR/sugar.bak.tgz ]
                    then
                        echo Database compressed on $BACKUP_DIR/sugar.sql.tgz
                        rm $BACKUP_DIR/sugar.sql
                    fi
                else
                    echo Database NOT backed up!!! Please check that the \"sugar\" database exists!
                    echo Please discard the current backup
                fi
            else
                echo For the backup and restore process to work, the database name should be \"sugar\"
                echo Backup aborted
            fi
        else
            if [ ! -d 'data' ]
            then
                echo \"data\" cannot be empty, the command needs to be executed from within the clone of the repository
            fi

            if [ ! -d 'data/app/sugar' ]
            then
                echo \"data/app/sugar\" cannot be empty
            fi

            if [ -d $BACKUP_DIR ]
            then
                echo $BACKUP_DIR exists already
            fi
        fi

    else
        echo The stack is not running, please start the stack first
    fi
fi
