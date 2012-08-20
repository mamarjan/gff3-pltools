gff3-select(1) -- converting GFF3/GTF files into table format
=============================================================

## SYNOPSIS

`gff3-select` SELECTION [-|GFF3_FILE] [-o OUTPUT_FILE] [OPTIONS]

`gff3-select` --help

`gff3-select` --version

## DESCRIPTION

**gff3-select** extracts the selected GFF3 fields and/or attributes
from a file and outputs them in a tab-separated table format, one
line per one GFF3 line.

Beside the defaults, it supports GTF as input, and JSON as output
format.

## OPTIONS

General options:

 * `-o`, `--output OUT`:
   Output will be written to the file <var>out</var>, instead of stdout.

 * `--gtf-input`:
   Input data is in GTF format.

 * `--json`:
   Output in JSON format.

 * `--version`:
   Output version information and exit.

 * `--help`:
   Print usage information and exit.

## EXAMPLES

To extract the feature type, start and stop coordinates, and the ID
attribute:

    $ gff3-select "feature,start,end,attr ID"  m_hapla.annotations.gff3

The same for GTF data:

    $ gff3-select "feature,start,end,attr geneid"  m_hapla.annotations.gtf \
          --gtf-input

or:

    $ gtf-select "feature,start,end,attr geneid"  m_hapla.annotations.gtf


## BUGS

See https://github.com/mamarjan/gff3-pltools/issues

## COPYRIGHT

`gff3-select` is copyright (C) 2012 Marjan Povolni.

## SEE ALSO

gff3-filter(1), gff3-ffetch(1)



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
