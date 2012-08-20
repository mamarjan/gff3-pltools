gff3-count-features(1) -- correctly count GFF3 features
=======================================================

## SYNOPSIS

`gff3-count-features` GFF3_FILE

`gff3-count-features` --version

## DESCRIPTION

**gff3-count-features** correctly counts the number of features in a
GFF3 file. This can be important for testing if the choosen size of
the feature cache while parsing a GFF3 file is big enough.

## OPTIONS

General options:

 * `--version`:
   Output version information and exit.

## EXAMPLES

To count the number of features in a GFF3 file:

    $ gff3-count-features m_hapla.annotations.gff3

## BUGS

See https://github.com/mamarjan/gff3-pltools/issues

## COPYRIGHT

`gff3-count-features` is copyright (C) 2012 Marjan Povolni.

## SEE ALSO

gff3-filter(1), gff3-ffetch(1), gff3-select(1)



[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[OPTIONS]: #OPTIONS "OPTIONS"
[EXAMPLES]: #EXAMPLES "EXAMPLES"
[BUGS]: #BUGS "BUGS"
[COPYRIGHT]: #COPYRIGHT "COPYRIGHT"
[SEE ALSO]: #SEE-ALSO "SEE ALSO"


[gff3-count-features(1)]: gff3-count-features.1.html
[gff3-to-gtf(1)]: gff3-to-gtf.1.html
[gff3-ffetch(1)]: gff3-ffetch.1.html
[gff3-to-json(1)]: gff3-to-json.1.html
[gff3-sort(1)]: gff3-sort.1.html
[gtf-to-gff3(1)]: gtf-to-gff3.1.html
[gff3-select(1)]: gff3-select.1.html
[gff3-filter(1)]: gff3-filter.1.html
