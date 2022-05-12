# NAME

Module::ScanDeps::Static - a cleanup of rpmbuild's perl.req

# SYNOPSIS

    my $scanner = Module::ScanDeps::Static->new({ file => 'myfile.pl' });
    $scanner->parse;
    print $scanner->get_dependencies;

# DESCRIPTION

This module is a mashup (and cleanup) of the \`/usr/lib/rpm/perl.req\`
file found in the rpm build tools library (see ["LICENSE"](#license)) below.

Successful identification of the required Perl modules for a module or
script is the subject of more than one project on CPAN. While each
approach has its pros and cons I have yet to find a better scanner
than the simple parser that Ken Estes wrote for the rpm build tools
package.

`Module::ScanDeps::Static` is a simple static scanner that
essentially uses regular expressions to locate `use`, `require`,
`parent`, and `base` in all of their disguised forms inside your
Perl script or module.  It's not perfect and the regular expressions
could use some polishing, but it works on a broad enough set of
situations as to be useful.

# WHAT IS A DEPENDENCY?

For the purposes of this module, dependencies are identified by
looking for Perl modules and other Perl artifacts declared using
`use`, `require`, `parent`, or `base`.

If the module contains a `require` statement, by default the
`require` must be flush up against the left edge of your script
without any whitespace between it and beginning of the line.  This is
the default behavior to avoid identifying `require` statements that
are embedded in `if` statements. If you want to include all of
the targets of `require` statements as dependencies, set the
`include-require` option to a true value.

# MINOR IMPROVEMENTS TO `perl.req`

- Allow detection of `require` not at beginning of line.

    Use the `--include-require` to expand the definition of a dependency
    to any module or Perl script that is the argument of the `require`
    statement.

- Allow detection of the `parent`, `base` statemens use of curly braces.

    The regular expression and algorithm in `parse` has been enhanced to
    detect the use of curly braces in `use` or `parent` declarations.

- Exclude core modules.

    Use the `--no-core` option to ignore core modules.

- Add the current version of installed module if version not explicitly specified.

# CAVEATS

There are still many situations (including multi-line statements) that
will prevent this module from properly identifying a dependency. As
always, YMMV.

# METHODS AND SUBROUTINES

## new

    new(options)

Returns a `Module::ScanDeps::Static` object.

### Options

- include\_require

    Boolean value that determines whether to consider `require`
    statements that are not left-aligned to be considered dependencies.

    default: **false**

- core

    Boolean value that determines whether to include core modules as part
    of the dependency listing.

    default: **true**

- add\_version

    Boolean value that determines whether to include the version of the
    module currently installed if there is no version specified.

    default: **false**

## get\_require

After calling the `parse()` method, call this method to retrieve a
hash containing the dependencies and (potentially) their version
numbers.

    $scanner->parse

## parse

- parse a file

        my @dependencies = Module::ScanDeps::Static->new({ path => $path })->parse;

- parse from file handle

        my @dependencies = Module::ScanDeps::Static->new({ handle => $path })->parse;
        

- parse STDIN

        my @dependencies = Module::ScanDeps::Static->new->parse(\$script);

- parse string

        parse(\$script);

Scans the specified input and returns a list dependency objects. Each
element of the array is a hash reference where the key is the module
name and the value is version number.

Use the `get_dependencies` method to retrieve the dependencies
as a formatted string. Use the `get_require` and `get_perlreq`
methods to retrieve dependencies as a list of hash refs.

    my $scanner = Module::ScanDeps::Static->new({ path => 'my-script.pl' });
    my @dependencies = $scanner->parse;

## get\_dependencies

Returns a formatted list of dependencies.

As JSON:

    print $scanner->get_dependencies( format => 'json' )

    [
      {
       "name" : "Module::Name",
       "version" "version"
      },
      ...
    ]

..or as text:

    print $scanner->get_dependencies( format => 'text' )

    Module::Name >= version
    ...

In scalar context in the absence of an argument returns a JSON
formatted string. In list context will return a list of hashes that
contain the keys "name" and "version" for each dependency.

# AUTHOR

This module is largely a lift and drop of Ken Este's \`perl.req\` script
lifted from rpm build tools.

Ken Estes Mail.com kestes@staff.mail.com

The method \`parse\` is a cleaned up version of \`process\_file\` from the
same script.

Rob Lauer - <bigfoot@cpan.org>

# LICENSE

This statement was lifted right from `perl.req`...

> _The entire code base may be distributed under the terms of the
> GNU General Public License (GPL), which appears immediately below.
> Alternatively, all of the source code in the lib subdirectory of the
> RPM source code distribution as well as any code derived from that
> code may instead be distributed under the GNU Library General Public
> License (LGPL), at the choice of the distributor. The complete text of
> the LGPL appears at the bottom of this file._
>
> _This alternatively is allowed to enable applications to be linked
> against the RPM library (commonly called librpm) without forcing
> such applications to be distributed under the GPL._
>
> _Any questions regarding the licensing of RPM should be addressed to
> Erik Troan &lt;ewt@redhat.com_.>
