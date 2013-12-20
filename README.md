imgurdl
=======

imgurdl is a GNU/Linux bash script used to download imgur albums. I wrote this
specifically for large albums because the 'download' option provided by imgur doesn't
always work like it's intended to.

The script does not use the imgur API but rather relies on wget, grep, sed, and some
simple regular expressions.

To get more help, run the script with no arguments. This will display usage help by default.

Written and tested on Debian 3.11.10-1 (2013-12-04) x86_64 GNU/Linux.
