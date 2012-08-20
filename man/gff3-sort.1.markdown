gff3-sort(1) -- sort GFF3 file so records of a single feature are close to each-other
=====================================================================================

## SYNOPSIS

`gff3-sort` GFF3_FILE

`gff3-sort` --version

## DESCRIPTION

**gff3-sort** takes a GFF3 file and sorts it in such a way that
records which belong to the same feature and one after another.
The file is then ready to be parsed in a sequence order by the
GFF3 parser which is part of the gff3-pltools.

## OPTIONS

General options:

 * `-o`, `--output OUT`:
   Output will be written to the file <var>out</var>, instead of stdout.

 * `--keep-fasta`:
   Copy fasta data to output.

 * `--keep-comments`:
   Copy comment lines to output.

 * `--keep-pragmas`:
   Copy pragma lines to output.

 * `--json`:
   Output in JSON format.

 * `--version`:
   Output version information and exit.

## BUGS

See https://github.com/mamarjan/gff3-pltools/issues

## COPYRIGHT

`gff3-sort` is copyright (C) 2012 Marjan Povolni.

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
