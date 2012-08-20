gff3-to-json(1) -- convert GFF3/GTF file to JSON
=====================================================================================

## SYNOPSIS

`gff3-to-json` GFF3_FILE [OPTIONS]

`gtf-to-json` GTF_FILE [OPTIONS]

`gff3-to-json` --version

## DESCRIPTION

**gff3-to-json** takes a GFF3 or GTF file and converts the data in that file
to a custom JSON format. The default output is stdout, but the `-o`
option can be used to use an output file instead.

stdin can be used as the data source if "-" is specified instead of
the input file.

## OPTIONS

General options:

 * `-o`, `--output OUT`:
   Output will be written to the file <var>out</var>, instead of stdout.

 * `--feature`:
   Instead of records, combine them into features and then output
   in a custom JSON format.

 * `--cache-size N`:
   Keep the last N features in cache which is used for combining
   records into features.

 * `--gtf-input`:
   Input data is in GTF format.

 * `--keep-comments`:
   Copy comment lines to output.

 * `--keep-pragmas`:
   Copy pragma lines to output.

 * `--version`:
   Output version information and exit.

 * `--help`:
   Print usage information and exit.

## BUGS

See https://github.com/mamarjan/gff3-pltools/issues

## COPYRIGHT

`gff3-to-json` is copyright (C) 2012 Marjan Povolni.

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
