# gff3-pltools

[![Build Status](https://secure.travis-ci.org/mamarjan/gff3-pltools.png)](http://travis-ci.org/mamarjan/gff3-pltools)

Note: this software is under active development!

**gff3-pltools** is a fast library and a suite of command line tools for
working with GFF3 and GTF.

## Installation

### Requirements

To build the tools from source, you'll need a DMDv2 or gdc compiler.
Download DMD from

  http://dlang.org/download.html

OS X users can install DMD using homebrew:

```sh
    brew install dmd
```

Optionally, rake is used to run the automated build scripts.

*Note*: the current trunk can't be built with GDC.

### Build and install instructions

Users of 32-bit and 64-bit Linux can download pre-build binary
packages.

For other plaforms download the source package, and build
with DMD like this:

```sh
    tar -zxvf gff3-pltools-X.Y.Z.tar.gz
    cd gff3-pltools-X.Y.Z
    rake utilities
    rake install
```

Given a recent version of the GDC compiler is installed, the utilities
can be build with it by using a different rake task:

```sh
    rake utilities:gdc
```

The binaries built with GDC currently work twice as fast, when compared
to binaries built with DMD.

Run rake with the -T option to see available rake tasks.

### Run tests

To run unittests execute the following command:

```sh
    rake test
```

## Usage

### gff3-ffetch utility

gff3-ffetch assembles sequences from a GFF3/GTF plus FASTA contig
file, and can produce FASTA, JSON and table output. Example

```sh
  gff3-ffetch CDS --parent-type mRNA m_hapla.WS232.genomic.fa m_hapla.WS232.annotations.gff3 
```

and translated to amino acids

```sh
  gff3-ffetch CDS --translate --parent-type mRNA m_hapla.WS232.genomic.fa m_hapla.WS232.annotations.gff3 
```

See manual page for more options and examples.

### gff3-filter utility

gff3-filter can filter a GFF3/GTF file, and render GFF3/GTF
output, as well as, JSON and table output. For example, the following command
can be used to keep only CDS features in a GFF3 file:

```sh
    gff3-filter "field feature == CDS" path-to-file.gff3
```

If you need to filter a GTF file instead, use --gtf-input and
--gtf-output options, or use the *gtf-filter* command instead.

The utility will use the fast (and soon parallel) D library to do the
parsing and filtering.

The parsing language supports any logical combination of a few
operators with values: field, attr,  ==, !=, >, <, >=, <=, +, -, *,
/, (, ), "and" and "or".

To keep only CDS features which have the ID attribute defined, the following
can be used:

```sh
    gff3-filter "(field feature == CDS) and (attr ID != \"\"" path-to-file.gff3
```

To keep records which are above 200 nucleotides in length, use this:

```sh
    gff3-filter "(field end - field start) > 200" path-to-file.gff3
```

Space is important, and has to be used to differentiate between elements,
except when braces are used. There is also no operator predecence, operations
are executed from left to right, and braces can be used to get different
operator precedence.

See manual page for more options and examples.

### gff3-select utility

This tool can be used to convert a GFF3 or GTF file to a
tab-separated table format, with columns being selected fields
and/or attributes.

For example:

```sh
    gff3-select "feature,start,end,attr ID" path-to-file.gff3
```

This will output a table with four columns, with the fields
feature, start and end, and the attribute ID.

### GFF3 File validation

The validation utility can be used like this:

```sh
    gff3-validate path/to/file.gff3
```

It will output any errors it finds to standard output. However, the
validation utility is currently very basic, and checks only for a few
cases: the number of columns, characters that should have been
escaped, are the start and stop coordinates integers and if the end
is greater then start, whether score is a float, valid values for
strand and phase, and the format of attributes.

### Benchmarking utility

There is a D application for performance benchmarking, which is useful only
while developing this library. It can be used like this:

```sh
    gff3-benchmark path/to/file.gff3
```

The most basic case for the banchmarking utility is to parse the file into
records, without replacing escaped characters. More functionality is available
using command line options:

```
  -v     turn on validation
  -r     turn on replacement of escaped characters
  -f     merge records into features
  -c N   feature cache size (how many features to keep in memory), default=1000
  -l     link feature into parent-child relationships
```

Before exiting, the utility prints the number of records or features
it parsed.

To use GTF files for benchmarking, uset the --gtf-input option or use
the "gtf-benchmark" command instead. There is also no support for validation
of GTF data.

### Counting features

The gff3-benchmark utility keeps only a small part of records in memory
while combining them into features. To check if the cache size is
correct, the "gff3-count-features" utility can be used to get the
correct number of features in a file. It gets all the IDs into
memory first, and then devises the correct number of features.

To get the correct number of features in a file, use the following
command:

```sh
    gff3-count-features path/to/file.gff3
```

### Format conversion utilities

There are a few conversion utilities: gff3-to-json, gff3-to-gtf and
gtf-to-gff3.

Conversion from GTF to GFF3 and back is only on the syntax level,
which means that the attributes column is reformated so that it can
be interpreted by a parser for the target file format.

### GFF3 sorting utility

Currently the tool sorts the file so that records which are part of the
same feature are in successive rows. It makes two passes on the input
file, the first to collect information and the second to actually sort
the data. The speed depends on the input file size and the number of
records with the ID attribute specified, and is not very impressive.
But the expected worst-case memory footprint is less then half the size
of the input file.

```sh
    gff3-sort path/to/file.gff3
```

## Project home page

Project home page can be found at the following location:

  http://mamarjan.github.com/gff3-pltools/

For information on the source tree, issues and
how to contribute, see

  http://github.com/mamarjan/gff3-pltools

## Copyright

Copyright (c) 2012 Marjan Povolni. See LICENSE.txt for further details.

