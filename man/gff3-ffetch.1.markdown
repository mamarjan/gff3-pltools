gff3-ffetch(1) -- assemble sequences from GFF3 and FASTA files
==============================================================

## SYNOPSIS

`gff3-ffetch` feature [--parent-type p-feature] [FASTA_FILE] GFF3_FILE... [-o OUTPUT_FILE] [OPTIONS]

`gff3-ffetch` --help

`gff3-ffetch` --version

## DESCRIPTION

**gff3-ffetch** assembles sequences of a single type, described in one
or more GFF3 annotation files and outputs them in FASTA format. It can
use the FASTA data attached to the GFF3 file, or a separate FASTA file
for the original sequences.

Even though the GFF3 specification says that the ID attribute should
be used to specify multiple parts of a single feature in multiple
records, experience shows that this is rarely used. In cases when the
parts have different IDs, or no IDs at all, the parent feature can be
used to assemble a feature from it's parts. The `--parent-type` option
should be use to use this grouping of features instead of the default.

The options `--phase`, `--frame` and `--trim-end` can be used to get a
better chance at getting a valid FASTA sequence, which can then be
translated to an amino acid sequence using the `--translate` option.

## OPTIONS

General options:

 * `--parent-type TYPE`:
   Use features of type <var>TYPE</var> to group records into features,
   instead of the ID attribute.

 * `--translate`:
   Output amino acid sequences.

 * `--fix`:
   Same as --phase, --frame and --trim-end combined.

 * `--no-assemble`:
   Turn off combining of records into features, and simply output one
   sequence per record.

 * `--phase`:
   Adjust each sequence part using the phase field from the record.

 * `--frame`:
   Adjust each sequence part by trying to predict the reading frame.
   Three options are tested (0, 1 and 2) and the one which gives the
   least number of stop codons is used.

 * `--trim-end`:
   The end of the sequence is trimmed so that the sequence lenght
   modulo 3 equals zero.

 * `-o`, `--output OUT`:
   Output will be written to the file <var>out</var>.

 * `--version`:
   Output version information and exit.

 * `--help`:
   Print usage information and exit.

Logging options:

 * `-q`:
   Run quietly, with warnings suppressed.

 * `-v`:
   Run verbosely, with additional informational messages. 
   
## EXAMPLES

To extract CDS sequences from a GFF3 file with appended FASTA data,
where one CDS feature equals one FASTA sequence, and the CDS recods
are grouped into features using the attribute ID:

    $ gff3-ffetch CDS m_hapla.annotations.gff3

The same, but with FASTA data in a separate file:

    $ gff3-ffetch CDS m_hapla.genomic.fa m_hapla.annotations.gff3

To use grouping by the same parent feature, use the following:

    $ gff3-ffetch CDS --parent-type mRNA m_hapla.genomic.fa \
          m_hapla.annotations.gff3

To ge the best chance at having a valid sequence which can be
translated to a protein sequence, use the --fix option:

    $ gff3-ffetch CDS --parent-type mRNA m_hapla.genomic.fa \
          m_hapla.annotations.gff3 --fix --translate

## BUGS

See https://github.com/mamarjan/gff3-pltools/issues

## COPYRIGHT

`gff3-ffetch` is copyright (C) 2012 Marjan Povolni.

## SEE ALSO

gff3-filter(1), gff3-select(1)



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
