#! /bin/bash
set -u

#LOGFILE=/var/lib/sabnzbd/scripts/sab_proc.log
CATEGORY_MOVIE="movies"
CATEGORY_TV="tv"

MOVIE_FOLDER="/data/plex/public/movies"
TV_FOLDER="/data/plex/public/tv"

MOVIE_SIZE="+629145600c"
TV_SIZE="+73400320c"

MOVIE_TYPES=("avi" "mkv" "wmv" "mp4")
TV_TYPES=("avi" "mkv" "wmv" "mp4")

CATEGORY_NAME=$5

FOLDER_PATH="$1"
FOLDER_NAME=`echo $FOLDER_PATH | awk -F [/] '{print $NF}'`



function process_movie {
    for e in "${MOVIE_TYPES[@]}"
    do
        echo "looking for movie extension $e" # >> $LOGFILE
        if [ `find . -size $MOVIE_SIZE -iregex ".*/.*\.$e" | wc -l` -eq 1 ]; then
            #Get the path for the movie
            FILEZ[1]="$FOLDER_PATH`find . -size $MOVIE_SIZE -iregex ".*/.*\.$e" | sed 's/^\.//'`"
            echo "Making Folder..." # >> $LOGFILE
            #Make Folder for the avi
            mkdir "$MOVIE_DESTINATION_DIRECTORY/$MOVIE_NAME"
            echo "Moving Files..." # >> $LOGFILE
            #Move the avi to the folder
            mv "${FILEZ[1]}" "$MOVIE_DESTINATION_DIRECTORY/$MOVIE_NAME/$MOVIE_NAME.$e"
            #If there's an nfo, move that into the folder as well
            if [ `find . -regex '.*/.*\.nfo' | wc -l` -gt 0 ]; then
                FILEZ[2]="$FOLDER_PATH`find . -regex '.*/.*\.nfo' | sed 's/^\.//'`"
                mv "${FILEZ[2]}" "$MOVIE_DESTINATION_DIRECTORY/$MOVIE_NAME/$MOVIE_NAME.nfo"  
            fi
            chmod 777 -R "${MOVIE_DESTINATION_DIRECTORY}"/"${MOVIE_NAME}"
            rm -r "$FOLDER_PATH"  
            echo "Removing Folder: $FOLDER_NAME..." # >> $LOGFILE
            break
        else
            echo "Couldn't copy(too many files or no files?)" # >> $LOGFILE
        fi
    #fi
    done
}

function process_series {
    for e in "${TV_TYPES[@]}"
    do
        if [ `find . -size $TV_SIZE -iregex ".*/.*\.$e" | wc -l` -eq 1 ]; then
            FILEZ[1]="$FOLDER_PATH`find . -size $TV_SIZE -iregex ".*/.*\.$e" | sed 's/^\.//'`"
            echo "One file found, making directories..." # >> $LOGFILE
            mkdir "$TV_DESTINATION_DIRECTORY/$SHOW_NAME"
            mkdir "$TV_DESTINATION_DIRECTORY/$SHOW_NAME/Season $SEASON_NUMBER"
            echo "Moving File..." # >> $LOGFILE
            mv "${FILEZ[1]}" "$TV_DESTINATION_DIRECTORY/$SHOW_NAME/Season $SEASON_NUMBER/$OPT_NAME.$e"
            echo "Removing Folder..." # >> $LOGFILE
            chmod 777 -R "${TV_DESTINATION_DIRECTORY}"/"${SHOW_NAME}"
            rm -r "$FOLDER_PATH"
        else
            echo "Couldn't copy(too many files or no files?)" # >> $LOGFILE
        fi
    done
}


####################
# main             #
####################

echo $2 # >> $LOGFILE
echo "Category: $CATEGORY_NAME" # >> $LOGFILE
echo "Folder Path: $FOLDER_PATH" # >> $LOGFILE

cd "$FOLDER_PATH"

####################
# Movie Processing #
####################

if [ $CATEGORY_NAME = $CATEGORY_MOVIE ]; then
    echo "Beginning Movie Processing..." # >> $LOGFILE

    # Where do you want to put the movies that this script processes?
    MOVIE_DESTINATION_DIRECTORY=$MOVIE_FOLDER
    MOVIE_NAME=`echo $FOLDER_NAME | sed 's/ (.*)//g'`
    echo "Movie Name: $MOVIE_NAME" # >> $LOGFILE

    # process the movie
    process_movie
fi

#################
# TV Processing #
#################

if [ $CATEGORY_NAME = $CATEGORY_TV ]; then
    #echo "Beginning TV Processing..." # >> $LOGFILE
    ##Where is your root TV directory? This script will create folders in it, i.e. ROOT_TV/Seinfeld/Season 8/...
    #TV_DESTINATION_DIRECTORY=$TV_FOLDER

    #if [ `echo $FOLDER_NAME | awk -F " - " '{print NF}'` -ne 3 ]; then
    #    echo $FOLDER_NAME | awk -F " - " '{print NF}' # >> $LOGFILE
    #    echo "Folder name incorrect, quitting..." # >> $LOGFILE
    #    exit 0
    #fi
    #OPT_NAME=`echo $FOLDER_NAME | sed 's/ (.*)//g'`
    #SHOW_NAME=`echo $OPT_NAME | awk -F " - " '{print $1}'`

    #echo "Show Name: $SHOW_NAME" # >> $LOGFILE
    #SEASON_NUMBER=`echo $OPT_NAME | awk -F " - " '{print $2}' | awk -F "x" '{print $1}'`
    #echo "Season Number: $SEASON_NUMBER" # >> $LOGFILE
    #EPISODE_NUMBER=`echo $OPT_NAME | awk -F " - " '{print $2}' | awk -F "x" '{print $2}'`

    # process the serieus
    #process_series

    echo "Use sickbeard integration for tv postprocessing" # >> $LOGFILE       
fi

echo "Done!" # >> $LOGFILE

