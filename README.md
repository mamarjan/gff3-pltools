# gff3-pltools

[![Build Status](https://secure.travis-ci.org/mamarjan/gff3-pltools.png)](http://travis-ci.org/mamarjan/gff3-pltools)

Note: this software is under active development!

This is currently an early work in progress to create parallel GFF3
and GTF parallel tools for D and a Ruby gem which would let Ruby
programmers use those tools from Ruby.

## Installation

### Requirements

The binary builds are self-contained.

To build the tools from source, you'll need the DMDv2 compiler in
your path. You can check here if there is a build of DMD available
for your platform:

  http://dlang.org/download.html

Also, the rake utility is necessary to run the automated build
scripts.

### Build and install instructions

Users of 32-bit and 64-bit Linux can download pre-build binary gems
and install them using the gem command:

```sh
    gem install bio-gff3-pltools-linux32-X.Y.Z.gem
```

Users of other plaforms can download the source package, and build
it themselves given the DMD compiler is available for their platform.

To build and install a gem for your platform, use the following steps:

```sh
    tar -zxvf bio-gff3-pltools-X.Y.Z.tar.gz
    cd bio-gff3-pltools-X.Y.Z
    rake install
```

To build a gem without installing, use the rake task "build" instead
of install in the previous example.

To build the binary tools without building a gem or a Ruby library,
invoke the "utilities" rake task instead and copy the binaries from
the "bin/" directory to your PATH.

### Run tests

You can use the "unittests" rake task to run D unittests, like this:

```sh
    rake unittests
```

To run tests for the Ruby library, first build the D utilities and
then start the "features" rake task, like this:

```sh
    rake utilities
    rake features
```

## Usage

### Ruby library

```ruby
    require 'bio-gff3-pltools'
```

TODO: Generate API docs and find a nice place for them somewhere on
the net.

The API doc is online. For more code examples see the test files in
the source tree.

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
like this: "\:".

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

However, the two last options are not completely the same. In cases
where an attribute has multiple values, the Parent attribute for
example, the "attribute" predicate first runs the contained predicate
on all attribute's values and returns true when an operation
returns true for a parent value. That is, it has an implicit and
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

### GFF3 File validation

The validation utility can be used like this:

```sh
    ./validate-gff3 path/to/file.gff3
```

It will output any errors it finds to standard output.

### Benchmarking utility

There is a small D application for performance benchmarking.
You can run it like this:

```sh
    ./benchmark-gff3 path/to/file.gff3
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
        
## Project home page

For information on the source tree, documentation, examples, issues and
how to contribute, see

  http://github.com/mamarjan/gff3-pltools

The BioRuby community is on IRC server: irc.freenode.org, channel: #bioruby.

## Cite

If you use this software, please cite one of
  
* [BioRuby: bioinformatics software for the Ruby programming language](http://dx.doi.org/10.1093/bioinformatics/btq475)
* [Biogem: an effective tool-based approach for scaling up open source software development in bioinformatics](http://dx.doi.org/10.1093/bioinformatics/bts080)

## Biogems.info

This Biogem is published at [#bio-gff3-pltools](http://biogems.info/index.html)

## Copyright

Copyright (c) 2012 Marjan Povolni. See LICENSE.txt for further details.

