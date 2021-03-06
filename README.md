Simple Site Builder
==============================

Builds static site with dhtml-tree-like navigation out of the given direcorties & html templates

## Quick info
Language(s): Perl
IDE(s): vim, perl -d
Platform: any (tested on Windows, Linux, Mac)

## License
(c) Sergey Vinogradov, 2008-2012.
You may use it and redistribute as you wish, but please, leave a note about the author.
Thanks.

## About
SimpleSiteBuilder converts a bunch of .html-s stored in directory tree into a publishable site with easy navigation...

## Input
* one or many dirs under 'data' dir, each of them called 'Modules'
    * within them two dirs: src and dest
        * 'src' is a set of directories with files (html, flv, images) to be processed
        * 'dest' is the result of processing
        * per-module setting are stored in 'data/XXX/src/head.txt'
* SimpleSiteBuilder itself - converter.pl and bunch of perl modules, located in '_dev' dir
* HTML templates in '_dev/SimpleConverter/lib/SRGB/XSPT' (part of SimpleSiteBuilder, but you may modify them easily)
Output:
* 'data/XXX/dest' will contain set of HTML pages with single navigation and style

## Look also at
* 'https://github.com/sergey-vin/SimpleSiteBuilder/wiki' for more info
* and this - ./_dev/SimpleConverter/readme.txt for more detailed tech info.
* and this - ./data/example_site/src/head.txt for per-module settings


