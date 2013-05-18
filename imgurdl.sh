#!/bin/bash

if [ $# -ne 1 ]
then
	echo "basename $0 <album url>"
	exit 1
fi
# The album's source URL. The trailing slash is removed and "/noscript" is added. When
# the source URL is established, download the HTML index file and parse it. We should
# then have a list of URLs to each file in the album.
HTML=$(wget -qO- "${1%/}/noscript")
URLS=$(grep "<img src=\"http://i.imgur.com/" <<< "$HTML" | sed -n 's/.*<img src="\([^"]*\)".*/\1/p')
URL_COUNT=$(wc -l <<< "$URLS")

# If there're any images in the album, download them.
if [ $URL_COUNT -gt 0 ]
then
	# Create the output directory.
	DESTINATION=$(grep "<title>" <<< "$HTML" | sed 's/<title>//; s/[ \t]*//')
	mkdir -p "$DESTINATION"
	if [ -d "$DESTINATION" ]
	then
		echo -n "Found $URL_COUNT images. Downloading $DESTINATION... "
		wget -P "$DESTINATION" -ci- -o /dev/null <<< "$URLS"
		echo "Done."
	fi
fi
exit 0
