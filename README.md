# NAME

Module::ScanDeps::Static - a cleanup of rpmbuild's perl.req

# SYNOPSIS

    my $scanner = Module::ScanDeps::Static->new({ file => 'myfile.pl' });
    $scanner->parse;
    print $scanner->format_text;

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

_NOTE: Only direct dependencies are returned by this module. If you
want a recursive search for dependencies, use `scandeps.pl`_

_!!EXPERIMENTAL!!_

_The methods and output of this module are subject to revision!_

# USAGE

    scandeps-static.pl [options] Module

If "Module" is not provided, the script will read from STDIN.

## Examples

    scandeps-static.pl --no-core $(which scandeps-static.pl)

    scandeps-static.pl --json $(which scandeps-static.pl)

## Options

- --add-version, -a, --no-add-version

    Add the version number to the dependency list by inspecting the version of
    the module in your @INC path.

    default: **--add-version**

- --core, -c, --no-core

    Include or exclude core modules. See --min-core-version for
    description of how core modules are identified.

    default: **--core**

- --help, -h

    Show usage.

- --include-require, -i, --no-include-require

    Include statements that have `Require` in them but are not
    necessarily on the left edge of the code (possibly in tests).

    default: <--include-require>

- --json, -j

    Output the dependency list as a JSON encode string.

- --min-core-version, -m

    The minimum version of Perl that is considered core. Use this to
    consider some modules non-core if they did not appear until after the
    `min-core-version`.

    Core modules are identified using `Module::CoreList` and comparing
    the first release value of the module with the the minimum version of
    Perl considered as a baseline.  If you're using this module to
    identify the dependencies for your script **AND** you know you will be
    using a specific version of Perl, then set the `min-core-version` to
    that version of Perl.

    default: 5.8.9

- --separator, -s

    Use the specified sting to separate modules and version numbers in formatted output.

    default: ' => '

- --text, -t

    Output the dependency list as a simple text listing of module name and
    version in the same manner as `scandeps.pl`.

    default: **--text**

- --raw, -r

    Output the list with no quotes separated by a single whitespace
    character.

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
may prevent this module from properly identifying a dependency. As
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

- add\_version

    Boolean value that determines whether to include the version of the
    module currently installed if there is no version specified.

    default: **false**

- core

    Boolean value that determines whether to include core modules as part
    of the dependency listing.

    default: **true**

- json

    Boolean value that indicates output should be in JSON format.

    default: **false**

- min\_core\_version

    The minimum version of Perl which will be used to decide if a module
    is include in Perl core.

    default: 5.8.9

- separator

    Character string to use formatting dependency list as text. This
    string will be used to separate the module name from the version.

    default: ' => '

        Module::ScanDeps::Static 0.1

- text

    Boolean value that indicates output should be in the same format as `scandeps.pl`.

    dafault: **true**

- raw

    Boolean value that indicates output should be in raw format (module version).

    default: **falue**

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

        my @dependencies = parse(\$script);

Scans the specified input and returns a list Perl modulde dependencies.

Use the `get_dependencies` method to retrieve the dependencies as a
formatted string or as a list of dependency objects. Use the
`get_require` and `get_perlreq` methods to retrieve dependencies as
a list of hash refs.

    my $scanner = Module::ScanDeps::Static->new({ path => 'my-script.pl' });
    my @dependencies = $scanner->parse;

## get\_dependencies

Returns a formatted list of dependencies or a list of dependency objects.

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

# VERSION

0.4

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
