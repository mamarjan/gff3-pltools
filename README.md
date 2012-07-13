# gff3-pltools

[![Build Status](https://secure.travis-ci.org/mamarjan/gff3-pltools.png)](http://travis-ci.org/mamarjan/gff3-pltools)

Note: this software is under active development!

This is currently an early work in progress to create parallel GFF3
and GTF parser library and tools in D.

## Installation

### Requirements

The binary builds are self-contained.

To build the tools from source, you'll need the DMDv2 compiler in
your path. You can check here if there is a build of DMD available
for your platform:

  http://dlang.org/download.html

OS X users can install DMD using homebrew:

```sh
    brew install dmd
```

Also, the rake utility is necessary to run the automated build
scripts.

### Build and install instructions

Users of 32-bit and 64-bit Linux can download pre-build binar packages
and install them by copying the binaries to somewhere in the PATH.

Users of other plaforms can download the source package, and build
it themselves given the DMD compiler is available for their platform.

To build the binaries, download the source and use the "utilities"
task:

```sh
    tar -zxvf gff3-pltools-X.Y.Z.tar.gz
    cd gff3-pltools-X.Y.Z
    rake utilities
```

### Run tests

The DMD compiler and rake utility are required to run the tests. You
can use the "unittests" rake task to run D unittests, like this:

```sh
    rake unittests
```

## Usage

### gff3-ffetch utility

Currently this utility supports only filtering a file, based on a
filtering expression. For example, you can use the following command
to filter out records with a CDS feature from a GFF3 file:

```sh
    gff3-ffetch --filter field:feature:equals:CDS path-to-file.gff3
```

The utility will use the fast (and soon parallel) D library to do the
parsing and filtering. You can then parse the result using your
programming language and library of choice.

Currently supported predicates are "field", "attribute", "equals",
"contains", "starts_with" and "not". You can combine them in a way
that makes sense. First, the utility needs to know what field or
attribute should be used for filtering. In the previous example,
that's the "field:feature" part. Next, the utility needs to know
what you want to do with it. In the example, that's the "equals"
part. And then the last part in the example is a parameter to the
"equals", which tells the utility what the attribute or field
should be compared to.

Parts of the expression are separated by a colon, ':', and if colon
is suposed to be part of a field name or value, it can be escaped
like this: "\\:".

Valid field names are: seqname, source, feature, start, end, score,
strand and phase.

A few more examples...

```sh
    gff3-ffetch --filter attribute:ID:equals:gene1 path-to-file.gff3
```

The previous example chooses records which have the ID attribute
with the value gene1.

To see which records have no ID value, or ID which is an empty
string, use the following command:

```sh
    gff3-ffetch --filter attribute:ID:equals: path-to-file.gff3
```

And to get records which have the ID attribute defined, you can use
this command:

```sh
    gff3-ffetch --filter attribute:ID:not:equals: path-to-file.gff3
```

or

```sh
    gff3-ffetch --filter not:attribute:ID:equals: path-to-file.gff3
```

However, the last two commands are not completely the same. In cases
where an attribute has multiple values, the Parent attribute for
example, the "attribute" predicate first runs the contained predicate
on all attribute's values and returns true when an operation
returns true for a parent value. That is, it has an implicit "and"
operation built-in.

There are a few more options available. In the examples above, the
data was comming from a GFF3 file which was specified on the command
line and the output was the screen. To use the standard input as the
source of the data, use "-" instead of a filename.

The default for output is the screen, or stdout. To redirect the
output to a file, you can use the "--output" option. Here is an
example:

```sh
    gff3-ffetch --filter not:attribute:ID:equals: - --output tmp.gff3
```

To limit the number of records in the results, you can use the
"--at-most" option. For example:

```sh
    gff3-ffetch --filter not:attribute:ID:equals: - --at-most 1000
```

If there are more then a 1000 records in the results, after the
1000th record printed, a line is appended with the following content:
"# ..." and the utility terminates.

To pass through the FASTA data contained in a GFF3 file, you can use
the "--pass-fasta-through" option. If there is FASTA data in it, it
will be copies to output after the GFF3 records.

To keep the comments and/or pragmas in the output, you can use the
--keep-comments/--keep-pragmas command line options.

### GFF3 File validation

The validation utility can be used like this:

```sh
    ./gff3-validate path/to/file.gff3
```

It will output any errors it finds to standard output. However, the
validation utility is currently very basic, and checks only for a few
cases: the number of columns, characters that should have been
escaped, are the start and stop coordinates integers and if the end
is greater then start, whether score is a float, valid values for
strand and phase, and the format of attributes.

### Benchmarking utility

There is a D application for performance benchmarking.
You can run it like this:

```sh
    ./gff3-benchmark path/to/file.gff3
```

The most basic case for the banchmarking utility is to parse the
file into records. More functionality is available using command
line options:

```
  -v     turn on validation
  -r     turn on replacement of escaped characters
  -f     merge records into features
  -c N   feature cache size (how many features to keep in memory), default=1000
  -l     link feature into parent-child relationships
```

Before exiting the utility prints the number of records or features
it parsed.

### Counting features

The gff3-ffetch utility keeps only a small part of records in memory
while combining them into features. To check if the cache size is
correct, the "gff3-count-features" utility can be used to get the
correct number of features in a file. It gets all the IDs into
memory first, and then devises the correct number of features.

To get the correct number of features in a file, use the following
command:

```sh
    ./gff3-count-features path/to/file.gff3
```

## Project home page

Project home page can be found at the following location:

  http://mamarjan.github.com/gff3-pltools/

For information on the source tree, issues and
how to contribute, see

  http://github.com/mamarjan/gff3-pltools

## Copyright

Copyright (c) 2012 Marjan Povolni. See LICENSE.txt for further details.

