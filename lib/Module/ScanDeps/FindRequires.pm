package Module::ScanDeps::FindRequires;

# modulino to find and maintain Perl dependencies

use strict;
use warnings;

use Cwd;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Find;
use File::Temp qw(tempfile);
use List::Util qw(any);
use JSON;
use Module::ScanDeps::Static;
use Scalar::Util qw(reftype);

use Readonly;

Readonly our $TRUE    => 1;
Readonly our $FALSE   => 0;
Readonly our $EMPTY   => q{};
Readonly our $SUCCESS => 0;
Readonly our $FAILURE => 1;

our $VERSION = '1.004';

use parent qw(CLI::Simple);

caller or __PACKAGE__->main();

########################################################################
sub find_requires {
########################################################################
  my ( $self, %args ) = @_;

  my $files = $args{files} // $self->get_files;

  my $requires;
  my @all_dependencies;
  my %requires_by_file;

  foreach my $f ( @{$files} ) {

    my $scanner = Module::ScanDeps::Static->new(
      { core            => $FALSE,
        include_require => $TRUE,
        path            => $f,
      }
    );

    $scanner->parse;

    my @dependencies = $scanner->format_json;
    $requires_by_file{$f} = \@dependencies;

    push @all_dependencies, @dependencies;
  }

  $self->set_requires_map( \%requires_by_file );

  return \@all_dependencies;
}

########################################################################
sub get_uniq_modules {
########################################################################
  my ( $self, %args ) = @_;

  my %modules;

  my $requires = $args{requires};

  foreach ( @{$requires} ) {
    # TODO: if dupes and versions are not equal take highest
    $modules{ $_->{name} } = $_->{version};
  }

  return \%modules;
}

########################################################################
sub get_module_paths {
########################################################################
  my ( $self, $modules ) = @_;

  my @module_paths;

  foreach my $module ( keys %{$modules} ) {
    my ($path) = split /\s/xsm, $module;

    if ( $module =~ /[']([^']+)[']/xsm ) {
      $module = $1;
    }

    if ( $path =~ /[']([^']+)[']/xsm ) {
      $path = $1;
    }

    next
      if $path =~ /[.]pl$/xsm;

    $path =~ s/::/\//xsmg;

    if ( $path !~ /[.]pl/xsm ) {
      $path .= '.pm';
    }

    push @module_paths, sprintf '%s %s', $module, $path;
  }

  return \@module_paths;
}

########################################################################
sub filter_list {
########################################################################
  my ( $self, %args ) = @_;

  my ( $module_paths, $packages ) = @args{qw(paths packages)};

  my @modules;
  my @filter_list = @{ $self->get_filter_list };

  foreach my $module ( @{$module_paths} ) {
    my $file;

    ( $module, $file ) = split /\s/xsm, $module;

    next
      if any { $module eq $_ } @{$packages};

    next
      if any { $module =~ /^$_/xsm } @filter_list;

    push @modules, $module;  #
  }

  return \@modules;
}

########################################################################
sub slurp_file {
########################################################################
  my ($file) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or die "could not open $file for reading: $OS_ERROR";

  my $content = <$fh>;

  close $fh;

  return wantarray ? split /\n/xsm, $content : $content;
}

########################################################################
sub get_file_listing {
########################################################################
  my ( $self, %args ) = @_;

  # --file file
  return [ $self->get_file ]
    if $self->get_file && !$args{all};

  # --file-list manifest
  if ( $self->get_file_list ) {
    my @file_list = slurp_file $self->get_file_list;
    return \@file_list;
  }

  # --path (default)
  my $path = $args{path};

  my @files;

  eval {
    find(
      sub {
        return
          if /^[.]/xsm || !/[.]p(:?m|l)$/xsm;

        die 'done'
          if !$self->get_recurse && $path ne $File::Find::dir;

        push @files, $File::Find::name;
      },
      $path,
    );
  };

  return \@files;
}

########################################################################
sub get_package_list {
########################################################################
  my ( $self, %args ) = @_;

  my $files = $args{files};

  my @packages;

  foreach my $f ( @{$files} ) {
    my $content = slurp_file $f;

    while ( $content =~ /^package\s+([^;]+);$/xsmg ) {
      push @packages, $1;
    }
  }

  return @packages;
}

########################################################################
sub list_files {
########################################################################
  my ( $self, %args ) = @_;

  my $format    = $args{format}    // 'text';
  my $max_items = $args{max_items} // $self->get_max_items;

  my $path = $self->get_path;

  my $files = $self->get_file_listing( path => $path, all => $args{all} );

  if ($max_items) {
    $files = [ @{$files}[ ( 0 .. $max_items - 1 ) ] ];
  }

  return $self->_format( $files, format => $format );
}

########################################################################
sub _format {
########################################################################
  my ( $self, $obj, %args ) = @_;

  my $format = $args{format} //= $self->get_format // $EMPTY;

  if ( $format eq 'json' ) {
    print {*STDOUT} JSON->new->pretty->encode($obj);
  }
  elsif ( $format eq 'text' ) {
    if ( reftype($obj) eq 'ARRAY' ) {
      print {*STDOUT} join "\n", @{$obj};
    }
    else {
      print {*STDOUT} Dumper($obj);
    }

    return 0;
  }
  else {
    return $obj;
  }

  return 0;
}

########################################################################
sub list_packages {
########################################################################
  my ( $self, %args ) = @_;

  my $format = $args{format} // $self->get_format // 'text';

  my $files = $self->list_files( format => $EMPTY, max_items => 0, all => 1 );

  my @packages = $self->get_package_list( files => $files );

  my $sorted_packages = [ sort @packages ];

  return $format ? $self->_format( [ sort @packages ], format => $format ) : $sorted_packages;
}

########################################################################
sub list_requires {
########################################################################
  my ( $self, %args ) = @_;

  my $format = $args{format} // $self->get_format // 'json';

  my $requires = $self->find_requires( files => $self->list_files( format => $EMPTY ) );

  return $self->_format( $requires, format => $format );
}

########################################################################
sub create_requires {
########################################################################
  my ( $self, %args ) = @_;

  my $requires = $args{requires};

  my $format = $args{format} // $self->get_format // 'json';

  if ( !$requires ) {

    my $requires_raw = $self->list_requires( format => $EMPTY );

    my $modules = $self->get_uniq_modules( requires => $requires_raw );

    my $paths = $self->get_module_paths($modules);

    my $packages = $self->list_packages( format => $EMPTY );

    my $filtered_modules = $self->filter_list( paths => $paths, packages => $packages );

    $requires = { map { $_ => $modules->{$_} } @{$filtered_modules} };

    $requires = { requires => $requires, exclude => $self->get_filter_list // [] };
  }

  return $requires
    if !$format;

  if ( $format eq 'json' ) {
    print {*STDOUT} JSON->new->pretty->encode($requires);
  }
  else {
    $requires = $requires->{requires};

    print {*STDOUT} join "\n",
      map { sprintf 'requires "%s", "%s"', $_, $requires->{$_} } sort keys %{$requires};
  }

  return 0;
}

########################################################################
sub create_cpanfile {
########################################################################
  my ($self) = @_;

  my $requires = $self->fetch_requires;

  $self->create_requires( requires => $requires, format => 'text' );

  return 0;
}

########################################################################
sub dump_map {
########################################################################
  my ($self) = @_;

  $self->create_requires( format => q{} );

  my $format = $self->get_format // 'json';

  my $map = $self->get_requires_map;

  my %requirements;

  foreach my $f ( keys %{$map} ) {
    $requirements{$f} = { map { ( $_->{name} => $_->{version} ) } @{ $map->{$f} } };
  }

  if ( $format eq 'json' ) {
    print {*STDOUT} JSON->new->pretty->encode( \%requirements );
  }
  else {
    foreach my $m ( keys %requirements ) {
      print {*STDOUT} sprintf "%s\n", $m;
      my @map_w_version = map { sprintf "\t%s, %s\n", $_, $requirements{$m}->{$_} } sort keys $requirements{$m};
      print {*STDOUT} join q{}, @map_w_version;
    }

  }

  return 0;
}

########################################################################
sub fetch_requires {
########################################################################
  my ($self) = @_;

  my $requires_file = $self->get_requires;

  if ( !$requires_file ) {
    $requires_file = getcwd . '/requires';

    die "use --requires to set the requires file!\n"
      if !-e $requires_file;

    $self->set_requires($requires_file);
  }

  return JSON->new->decode( scalar slurp_file($requires_file) );
}

########################################################################
sub check_requires {
########################################################################
  my ($self) = @_;

  my $requires = $self->fetch_requires;

  my $new_requires = $self->list_requires( format => $EMPTY );
  my $packages     = $self->list_packages( format => $EMPTY );

  my @filters = @{ $self->get_filter_list // [] };

  push @filters, @{ $requires->{exclude} // [] };

  my @filtered_list;

  foreach my $m ( @{$new_requires} ) {
    # delete hash entries that match filter /^/
    my $module = $m->{name};

    next
      if any { $module =~ /^$_/xsm } @filters;

    push @filtered_list, $m;
  }

  my $retval = 0;
  my %new_required_modules;

  foreach my $m (@filtered_list) {
    my ( $name, $version ) = @{$m}{qw(name version)};

    # skip provided packages
    next
      if any { $name eq $_ } @{$packages};

    my $current_version = $requires->{requires}->{$name};

    if ( !defined $current_version ) {
      $new_required_modules{$name} = $version || 0;
      $retval = -1;
    }
    elsif ( $version ne $current_version ) {
      $new_required_modules{$name} = $version || 0;
      $retval = -1;
    }
  }

  if ($retval) {
    print {*STDOUT} JSON->new->pretty->encode( \%new_required_modules );
  }

  return $retval;
}

########################################################################
sub add_requires {
########################################################################
  my ($self) = @_;

  my $requires = $self->fetch_requires;
  my $module   = $self->get_module;

  if ($module) {
    my $version = $self->get_module_version;
    $requires->{requires}->{$module} = $version || '0';
  }
  else {
    local $RS = undef;

    my $modules = eval { return JSON->new->decode(<>); };

    if ( !$modules || $EVAL_ERROR ) {
      print {*STDERR} sprintf "no modules added %s\n", $EVAL_ERROR // $EMPTY;
    }
    else {
      foreach ( keys %{$modules} ) {
        $requires->{requires}->{$_} = $modules->{$_} || '0';
      }

      if ( $self->get_update ) {
        $self->update_requires($requires);
      }
      else {
        print {*STDOUT} JSON->new->pretty->encode($requires);
      }
    }
  }

  return 0;
}

########################################################################
sub delete_requires {
########################################################################
  my ($self) = @_;

  my $module = $self->get_module;

  die "use --module to set the module you want to delete from the requires list\n"
    if !$module;

  my $requires = $self->fetch_requires();

  delete $requires->{requires}->{$module};

  if ( $self->get_update ) {
    $self->update_requires($requires);
  }
  else {
    print {*STDOUT} JSON->new->pretty->encode($requires);
  }

  return 0;
}

########################################################################
sub update_requires {
########################################################################
  my ( $self, $requires ) = @_;

  my ( $fh, $tempfile ) = tempfile('requiresXXXXX');

  eval {
    print {$fh} JSON->new->pretty->encode($requires);
    close $fh;

    my $requires_file = $self->get_requires;

    if ( -e "$requires_file.bak" ) {
      unlink "$requires_file.bak";
    }

    rename $requires_file, "$requires_file.bak";

    rename $tempfile, $requires_file;
  };

  if ($EVAL_ERROR) {
    print {*STDERR} "error updating requires file $EVAL_ERROR\n";
    unlink $tempfile;
  }

  return;
}
########################################################################
sub main {
########################################################################

  my @option_specs = qw(
    file|f=s
    filter|F=s
    file-list|L=s
    format|t=s
    max-items|m=i
    module-version=s
    module|M=s
    path|p=s
    recurse|R!
    requires|r=s
    update
    versions|v
  );

  my $cli = Module::ScanDeps::FindRequires->new(
    option_specs    => \@option_specs,
    default_options => { path => getcwd },
    extra_options   => [qw(files packages requires_map filter_list)],
    commands        => {
      'create-cpanfile' => \&create_cpanfile,
      'create-requires' => \&create_requires,
      'list-packages'   => \&list_packages,
      'list-requires'   => \&list_requires,
      'list-files'      => \&list_files,
      'dump-map'        => \&dump_map,
      'check-requires'  => \&check_requires,
      'add-requires'    => \&add_requires,
      'delete-requires' => \&delete_requires,
    }
  );

  my @filter;

  if ( $cli->get_filter ) {
    @filter = slurp_file( $cli->get_filter );
  }

  my $recurse = $cli->get_recurse;

  $cli->set_recurse( defined $recurse ? $recurse : $TRUE );

  $cli->set_filter_list( \@filter );

  if ( $cli->get_file ) {
    $cli->set_max_items(0);
  }

  exit $cli->run();
}

1;

__END__

=pod

=head1 NAME

find-requires.pl

=head1 SYNOPSIS

 find-requires.pl --path src/main/perl list-requires

 find-requires.pl --path src/main/perl dump-map

=head1 DESCRIPTION

C<find-requires.pl> is a script to help you find and maintain a list
of dependencies for you Perl application. The script will help you
create a C<requires> file which can be used to produce a C<cpanfile>
typically used by L<Carton>.

The C<requires> file is a JSON file similar to the one shown below.

 {
  "requires" : [
     "DBI" : "1.643",
     "Readonly": "2.05",
     ...
   ],
  "exclude" : [
     ...
   ]
 }

When C<find-requires.pl> determines dependencies it will automatically
recognize Perl modules provided by your application.

=head2 Excluding Modules from the Dependency List

You can add entries to the C<exclude> list in the C<requires> file so
that specific modules will not be added to your dependency list. You
might want to do this if, for example, there are certain modules that
are not provided by CPAN and should not be listed in your final
C<cpanfile>. The script uses this list by essentially filtering the
final dependency list using a regular expression where the module to
be excluded "starts with" the string in your exclude list.

Let's suppose you have some custom Perl modules provided by another
application (not in CPAN) that have namespace of C<Foo>.

Adding C<Foo> to the exclude list will exclude all modules found as
dependencies that begin with C<Foo>.

=head2 Adding New Requirements

You can edit the C<requires> file and add new dependencies. You can
also allow the script to look for new dependencies and update the list
automatically (See L<RECIPES>).

The script can scan your entire application directory or a single file
while looking for new dependencies. This makes it ideal for making
sure your application depencencies are uptodate whenver a file is
modified.  If you are using C<git> as your version control system for
example, you can create a pre-commit hook that scans the file for new
dependencies and either halts the commit or automatically adds the
dependency before commiting the file.

=head1 USAGE

 find-requires.pl options command

 Script to maintain a manifest of Perl module dependencies for a project.

 Options
 -------
 --help, -h       help
 --file, -f       path to single file to scan
 --filter, -F     name of a file containing names of modules to exclude 
                  from requires list
 --format, -t     format of output (text|json)
 --max-items, -m  maximum number of files to scan 
 --module, -M     module to add when using 'add-requires'
 --module-version module version when adding module to requires list (default: 0)
 --no-recurse     do not recurse into subdirectories when lookin for files
 --path, -p       path to search for .pm & .pl files
 --requires, -r   name of the file containging the required modules and exclusion list
 --update, -u     update the requires file
 --versions, -v   include version numbers in output

 Commands
 --------
 add-requires       add a new required module to requires file
 check-requires     checks a single file (or all files for new depdenencies)
 create-cpanfile    creates a cpanfile from the requires file or as the output of a scan
 create-requires    creates the requires file (see below for format specification)
 dump-map           dumps a map of files and their dependencies
 list-files         lists files to be scanned
 list-packages      lists all packages found in files
 list-requires      lists the dependencies (unfiltered, raw output)

 Notes
 ----- 

 * files in the current directory and below will be scanned unless
   --path or --file is provided. Use --no-recurse to stop the scanner
   from traversing below the root of our you search path.

 * 'dump-map' will always do a re-scan either on a single file or the
   list of files if no --file is given

 * 'add-requires' will read a JSON formatted list of required modes
   from STDIN unless --module is provided. The format of the list is the
   same as that produced by 'check-requires' (see Recipes)

 * 'check-requires' will look for a file named 'requires' in the
   current working directory unless the --requires option is provided

 * 'check-requires' will return a 0 on success and -1 if new
   requirements are found facilitating use in bash scripts and
   Makefile recipes

=head1 RECIPES

I<Note: The recipes below that do not use the C<--path> option, assume
you are executing the script from the root of your application.>

=over 5

=item * create the C<requires> file the first time

   find-requires.pl --path src/main/perl create-requires > requires

=item * check to see if a module has a new requirement

   find-requires.pl -f src/main/perl/lib/TreasurersBriefcase/Foo.pm check-requires

=item * add new dependencies to the C<requires> file

   find-requires.pl --module Foo --module-version 0.1 add-requires

   find-requires.pl --file myscript.pl check-requires | \
      find-requires.pl -u add-requires

=item * delete a module from the C<requires> file

  find-requires.pl -M Foo::Bar::Baz -u delete-requires

=item * create a cpanfile from the C<requires> file

   find-requires.pl create-cpanfile

=item * create listing of each file and its dependencies

I<Note: C<dump-map> will always rescan the entire application
directory.>

  find-requires.pl dump-map

=back

=head1 SEE OTHER

L<Module::ScanDeps::Static>

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
