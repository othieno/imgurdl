#!/bin/bash
#
# The MIT License (MIT)
#
# Copyright (c) 2013 Jeremy Othieno.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# The substitute echo command.
ECHO="echo -e"

# By default, an album is downloaded.
MODE=album

# Flags.
FLAG_ALBUM="-a"
FLAG_USER="-u"

# The absolute path to this script.
SELF=$(cd $(dirname $0) ; pwd -P)/$(basename $0)


HELP=\
"Usage: $0 [mode] <url>
imgurdl.sh has two modes, one to download a single album and the other to
download multiple albums from a given user's page. By default, imgurdl
downloads a single album from the provided link, if it is valid.

Modes:
  $FLAG_ALBUM\tDownload an album from the given link.
  $FLAG_USER\tDownload a user's albums.

Examples:
  $0 http://imgur.com/a/wtwuu
  $0 $FLAG_ALBUM http://imgur.com/a/wtwuu
  $0 $FLAG_USER http://reactiongifsarchive.imgur.com/
"

# Check the number of arguments.
if [ $# -lt 1 ] || [ $# -gt 2 ]
then
   $ECHO "$HELP"
   exit 1
fi

# Get and validate the mode.
if [ $# -lt 2 ]
then
   URL=$1
elif [ $# -gt 1 ]
then
   URL=$2

   # The mode flag has been explicitly set, make sure it's valid.
   if [ "$1" = $FLAG_ALBUM ]
   then
      MODE=album
   elif [ "$1" = $FLAG_USER ]
   then
      MODE=user
   else
      $ECHO "Unknown mode '$1'."
      $ECHO "$HELP"
      exit 1
   fi
fi


if [ $MODE = user ]
then
   # Validate the target URL.
   URL=$(grep -o '.*\.imgur.com' <<< $URL)

   if [ -z "$URL" ]
   then
      $ECHO "Invalid URL. Make sure the URL links to an Imgur user's page."
      exit 1
   else
      # Get the username of the album's owner.
      USERNAME=$(sed 's/http:\/\///; s/.imgur.com//' <<< $URL)

      # The HTML index file at the given address is downloaded and parsed. When parsing is
      # completed, the 'ALBUMS' variable should contain a list of URLs to each of the user's
      # albums. If the HTML index file is empty, then this means an HTTP error was returned.
      HTML=$(wget -qO- "${URL%/}")
      if [ -z "$HTML" ]
      then
         $ECHO "The user '$USERNAME' does not exist."
         exit 1
      fi
      ALBUMS=$(grep -o 'id=\"album-.*\" ' <<< "$HTML" | sed 's/"//g; s/id=album-/http:\/\/imgur.com\/a\//; s/ .*//g')

      # If there're any albums, download them.
      NALBUMS=$(wc -l <<< "$ALBUMS")
      if [ $NALBUMS -lt 1 ]
      then
         $ECHO "No albums were found at '$URL'"
      else
         if [ $NALBUMS -lt 2 ]
         then
            $ECHO "imgurdl found $(tput bold)1$(tput sgr0) album for user '$(tput bold)$USERNAME$(tput sgr0)'.\n"
         else
            $ECHO "imgurdl found $(tput bold)$NALBUMS$(tput sgr0) albums for user '$(tput bold)$USERNAME$(tput sgr0)'.\n"
         fi

         # Create the destination directory for all albums.
         WORKDIR="imgur - $USERNAME's albums"
         mkdir -p "$WORKDIR"
         cd "$WORKDIR"

         # Download the albums.
         i=1
         for ALBUM in $ALBUMS
         do
            $ECHO -n "($i/$NALBUMS) "
            "$SELF" $FLAG_ALBUM $ALBUM
            ((++i))
         done

         # Show the number of successfully downloaded images.
         NIMAGES=$(find ./ -type f | wc -l)
         if [ $NIMAGES -lt 2 ]
         then
            $ECHO "\nimgurdl retrieved $(tput bold)1$(tput sgr0) image from $(tput bold)$USERNAME$(tput sgr0)'s albums."
         else
            $ECHO "\nimgurdl retrieved $(tput bold)$NIMAGES$(tput sgr0) images from $(tput bold)$USERNAME$(tput sgr0)'s albums."
         fi
      fi
   fi
elif [ $MODE = album ]
then
   # Remove any parameters in the URL.
   URL=$(grep -o ".*imgur.com/a/.*" <<< $URL | sed 's/#.*//g')

   if [ -z "$URL" ]
   then
      $ECHO "Invalid URL. Make sure the URL links to an Imgur album."
      exit 1
   else
      # The trailing slash is removed from the URL and "/noscript" is added. The HTML index
      # file at the given address is then downloaded and parsed. When parsing is completed,
      # the 'HASHES' variable should contain a list of URLs to each image in the album.
      HTML=$(wget -qO- "${URL%/}/noscript")
      if [ -z "$HTML" ]
      then
         $ECHO "The album '$URL' does not exist."
         exit 1
      fi
      HASHES=$(grep -o 'img src=\".*i.imgur.com/.*"' <<< "$HTML" | sed 's/"//g; s/.*\(i.imgur.com\/.*.*\).*/http:\/\/\1/g')

      # If there're any images in the album, download them.
      NHASHES=$(wc -l <<< "$HASHES")
      if [ $NHASHES -lt 1 ]
      then
         $ECHO "No images were found at '$URL'"
      else
         # Get the album's title. This will be its folder name on the local filesystem.
         TITLE=$(grep -Po 'data-title=".*?"' <<< "$HTML" | sed 's/data-title=//; s/"//g')

         # An empty title variable means the album is untitled.
         if [ -z "$TITLE" ]
         then
            TITLE="untitled"
            WORKDIR="untitled"
         else
            # Create the folder from the title, making sure there're no invalid characters.
            WORKDIR=$(sed 's/[ \t]*//; s/\//_/g; s/\x0//g' <<< "$TITLE")
         fi

         mkdir -p "$WORKDIR"
         if [ $NHASHES -lt 2 ]
         then
            $ECHO "Downloading 1 image from album '$TITLE'... "
         else
            $ECHO "Downloading $NHASHES images from album '$TITLE'... "
         fi
         wget -nv -c --no-cache --content-on-error -t 64 -P "$WORKDIR" -i- <<< "$HASHES"
      fi
   fi
fi
exit 0
