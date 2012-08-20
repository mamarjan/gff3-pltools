gtf-to-gff3(1) -- convert GTF file to GFF3 format
=====================================================================================

## SYNOPSIS

`gtf-to-gff3` GTF_FILE [OPTIONS]

`gtf-to-gff3` --version

## DESCRIPTION

**gtf-to-gff3** takes a GTF file and converts the data in that file
to GFF3 format. The default output is stdout, but the `-o` option can
be used to use an output file instead.

The difference between these two formats is in the format of the
ninth column, and all this tool is doing is to change the attributes
column from the GTF format to GFF3 format.

stdin can be used as the data source if "-" is specified instead of
the input file.

## OPTIONS

General options:

 * `-o`, `--output OUT`:
   Output will be written to the file <var>out</var>, instead of stdout.

 * `--version`:
   Output version information and exit.

## BUGS

See https://github.com/mamarjan/gff3-pltools/issues

## COPYRIGHT

`gtf-to-gff3` is copyright (C) 2012 Marjan Povolni.

## SEE ALSO

gff3-filter(1), gff3-ffetch(1), gff3-select(1)



[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[OPTIONS]: #OPTIONS "OPTIONS"
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
