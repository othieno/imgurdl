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

if [ $# -ne 1 ]
then
	echo "$0 <album url>, e.g. $0 http://imgur.com/a/wtwuu"
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
	# Create the output directory, making sure to validate the filename.
	DESTINATION=$(grep "<title>" <<< "$HTML" | sed 's/<title>//; s/[ \t]*//; s/\//_/g; s/\x0//g')
	mkdir -p "$DESTINATION"
	if [ -d "$DESTINATION" ]
	then
		echo -n "Found $URL_COUNT images. Downloading $DESTINATION... "
		wget -P "$DESTINATION" -ci- -o /dev/null <<< "$URLS"
		echo "Done."
	fi
fi
exit 0
