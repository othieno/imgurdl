imgurdl
=======

imgurdl is a small linux shell script used to download imgur albums. I wrote this
specifically for large albums because the 'download' option provided by imgur doesn't
always work like it's supposed to.

The script relies on wget, grep, sed and some simple regular expressions.

To run, simply launch the script with the sole parameter being the URL of the album.
For example, __./imgurdl http://imgur.com/a/wtwuu__


Tested on Debian 3.2.41-2 x86_64 GNU/Linux.
