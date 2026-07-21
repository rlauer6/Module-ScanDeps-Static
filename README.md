<a id="table-of-contents" class="anchor" aria-label="Permalink: Table of Contents" href="#table-of-contents"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Table of Contents</h1>
<ul>
<li><a href="#name">NAME</a></li>
<li><a href="#synopsis">SYNOPSIS</a></li>
<li>
<a href="#description">DESCRIPTION</a>
<ul>
<li><a href="#comparison-to-other-scanners">Comparison to Other Scanners</a></li>
</ul>
</li>
<li>
<a href="#options">OPTIONS</a>
<ul>
<li><a href="#examples">Examples</a></li>
</ul>
</li>
<li><a href="#option-details">OPTION DETAILS</a></li>
<li>
<a href="#what-is-a-dependency">WHAT IS A DEPENDENCY?</a>
<ul>
<li><a href="#dependency-tiers">Dependency Tiers</a></li>
<li><a href="#structural-classification">Structural Classification</a></li>
<li><a href="#the-##-scandeps-annotation">The <code>## scandeps:</code> Annotation</a></li>
<li><a href="#conflicting-classifications">Conflicting Classifications</a></li>
<li><a href="#self-referential-modules">Self-Referential Modules</a></li>
<li><a href="#dynamic-module-loading">Dynamic Module Loading</a></li>
</ul>
</li>
<li><a href="#minor-improvements-to-perlreq">MINOR IMPROVEMENTS TO <code>perl.req</code></a></li>
<li><a href="#caveats">CAVEATS</a></li>
<li>
<a href="#methods-and-subroutines">METHODS AND SUBROUTINES</a>
<ul>
<li>
<a href="#new">new</a>
<ul>
<li><a href="#options">Options</a></li>
</ul>
</li>
<li><a href="#get%5Crequire">get_require</a></li>
<li><a href="#get%5Cperlreq">get_perlreq</a></li>
<li><a href="#parse">parse</a></li>
<li><a href="#get%5Cdependencies">get_dependencies</a></li>
<li><a href="#format%5Ctext">format_text</a></li>
<li><a href="#format%5Cjson">format_json</a></li>
<li><a href="#format%5Ccpanfile">format_cpanfile</a></li>
<li><a href="#is%5Ccore">is_core</a></li>
<li><a href="#min%5Ccore%5Cversion">min_core_version</a></li>
<li><a href="#get%5Cmodule%5Cversion">get_module_version</a></li>
<li><a href="#add%5Crequire">add_require</a></li>
<li><a href="#to%5Crpm">to_rpm</a></li>
</ul>
</li>
<li><a href="#version">VERSION</a></li>
<li><a href="#author">AUTHOR</a></li>
<li><a href="#license">LICENSE</a></li>
</ul>
<a id="name" class="anchor" aria-label="Permalink: NAME" href="#name"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">NAME</h1>
<p>Module::ScanDeps::Static - a cleanup of rpmbuild's perl.req</p>
<a id="synopsis" class="anchor" aria-label="Permalink: SYNOPSIS" href="#synopsis"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SYNOPSIS</h1>
<pre><code>scandeps-static [options] Module
</code></pre>
<p>If "Module" is not provided, the script will read from STDIN.</p>
<pre><code>my $scanner = Module::ScanDeps::Static-&gt;new({ path =&gt; 'myfile.pl' });
$scanner-&gt;parse;
print $scanner-&gt;format_text;
</code></pre>
<a id="description" class="anchor" aria-label="Permalink: DESCRIPTION" href="#description"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">DESCRIPTION</h1>
<p>This module is a mashup (and cleanup) of the <code>/usr/lib/rpm/perl.req</code>
file found in the rpm build tools library (see <a href="#license">"LICENSE"</a>) below.</p>
<p>Successful identification of the required Perl modules for a module or
script is the subject of more than one project on CPAN. While each
approach has its pros and cons I have yet to find a better scanner
than the simple parser that Ken Estes wrote for the rpm build tools
package.</p>
<p><code>Module::ScanDeps::Static</code> is a simple static scanner that
essentially uses regular expressions to locate <code>use</code>, <code>require</code>,
<code>parent</code>, and <code>base</code> in all of their disguised forms inside your
Perl script or module.  It's not perfect and the regular expressions
could use some polishing, but it works on a broad enough set of
situations as to be useful.</p>
<p><em>Only direct dependencies are returned by this module. If you
want a recursive search for dependencies, use <code>find-requires</code>
included in this distribution.</em></p>
<a id="comparison-to-other-scanners" class="anchor" aria-label="Permalink: Comparison to Other Scanners" href="#comparison-to-other-scanners"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Comparison to Other Scanners</h2>
<p>Two other CPAN scanners cover similar ground:
<a href="https://metacpan.org/pod/Perl%3A%3APrereqScanner" rel="nofollow">Perl::PrereqScanner</a>, built on <a href="https://metacpan.org/pod/PPI" rel="nofollow">PPI</a>, and
<a href="https://metacpan.org/pod/Perl%3A%3APrereqScanner%3A%3ANotQuiteLite" rel="nofollow">Perl::PrereqScanner::NotQuiteLite</a> (here, "NQLite"), which uses its
own lexer. The comparison below reflects hands-on testing against
both, not just a reading of their documentation.</p>
<p><strong>Speed.</strong> This module is regex/line-based rather than a true
tokenizer, and that's a deliberate trade-off, not an oversight - it's
the source of most of the speed difference. On a representative
414-line file, this module scans in roughly 1.7ms; NQLite takes
roughly 6ms; PPI-based <code>Perl::PrereqScanner</code> takes roughly 45ms.
PPI's own documentation acknowledges this cost directly, describing
itself as "painful... with very large files." The trade-off cuts the
other way too: a real tokenizer is structurally immune to a class of
edge case (an unbalanced brace inside a string or heredoc, for
example) that this module's regex approach can, in principle, still
be fooled by, even though no such failure has been found in testing
against real-world code.</p>
<p><strong>Dependency classification.</strong> All three tools distinguish a hard
requirement from something merely conditional or optional, but this
module is alone in giving the developer an explicit way to state that
judgment rather than have it inferred. NQLite decides <code>recommends</code>
vs. <code>suggests</code> purely from code structure - specifically, whether
the call is a bare <code>eval</code> or one of two specific, by-name-recognized
CPAN modules (<a href="https://metacpan.org/pod/Module%3A%3ARuntime" rel="nofollow">Module::Runtime</a> and <a href="https://metacpan.org/pod/Class%3A%3ALoad" rel="nofollow">Class::Load</a>) - with no way
for a developer to say "no, that one's actually important" short of
restructuring their code to match what the scanner looks for. This
module instead classifies a guarded dependency as <code>suggests</code> by
default (or <code>recommends</code> project-wide via <code>eval_recommends</code>), and
lets a <code>## scandeps: recommends</code> or <code>## scandeps: suggests</code> comment
immediately after the guarding statement override that default
per-instance. Neither other tool has an equivalent escape hatch.</p>
<p>This module also warns - rather than silently picking a winner - when
a module is both a hard requirement in one place and merely
recommended or suggested in another, since that's a real contradiction
in the source worth surfacing to the developer, not something a
scanner should resolve on its own.</p>
<p><strong>Version numbers.</strong> Both <code>Perl::PrereqScanner</code> and NQLite report
every dependency's version as a fixed <code>0</code> placeholder - not "unknown",
literally the string <code>0</code> regardless of what's actually installed or
required. This module performs a real version lookup (see
<code>--add-version</code>) and reports what it actually finds.</p>
<p>Reporting a version number or <code>0</code> both have their advantages and
disadvantages. Users of these scanners can always edit the output and
modify the version number requirements, however this scanner opted to
choose the currently installed version. This assumes you are
developing your module against a known environment, and the idea is
that while other versions of a module might work, the version in your
working environment is known to work with your module. Selecting
<code>0</code> means any version will do - but consider a module like
<code>List::Util</code> running under Perl 5.10. While <code>List::Util</code> has been in
core since 5.7.3, its feature list has grown significantly. You may be
using features that were not present in that version of <code>List::Util</code>.
Shipping with the minimum version of <code>List::Util</code> set to <code>0</code> is
almost certainly going to fail on earlier versions of Perl.</p>
<p>The true minimum - the exact release in which every feature your code
actually relies on first appeared - would in principle be the most
accurate answer. But determining that reliably would mean downgrading
each dependency in turn and re-running your test suite against every
prior release, which presumes you have test coverage specifically
exercising the features you're relying on, for every dependency you
use. That's not a reasonable expectation in practice - reporting the
currently installed version is a deliberate trade-off in favor of a
version <strong>known</strong> to work over one merely presumed to.</p>
<p><strong>Self-referential modules.</strong> Scanning a whole project can turn a
sibling module into a false positive - file A's <code>use</code> of file B's
<code>package</code> isn't an external dependency at all. NQLite handles this
with <code>--private</code>, a manually maintained list of module names to
exclude. This module's <code>--filter</code> does the same job automatically,
by detecting <code>package</code> declarations across the batch being scanned,
at the cost of only working when the sibling file is actually part of
the same scan.</p>
<p><strong>What this module doesn't attempt.</strong> NQLite can infer a minimum Perl
version from newer syntax (signatures, <code>say</code>, and similar) appearing
in the source without an explicit <code>use v5.x</code> declaration; this module
does not attempt that. NQLite also has an opt-in <code>CPAN::Common::Index</code>
integration that can deduplicate module names belonging to the same
distribution - deliberately not pursued here, since it requires a
network round-trip (or a locally maintained mirror) per module found
at scan time, in exchange for a purely cosmetic shortening of the
output that changes nothing about what actually gets installed.
Finally, no static scanner - this one included - can discover a
dependency loaded through a genuinely dynamic mechanism (a module name
computed at runtime and passed to something like <a href="https://metacpan.org/pod/Module%3A%3ALoad" rel="nofollow">Module::Load</a>);
that's a fundamental limit of static analysis, not a gap specific to
any one tool. See <a href="#dynamic-module-loading">"Dynamic Module Loading"</a> below.</p>
<a id="options" class="anchor" aria-label="Permalink: OPTIONS" href="#options"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">OPTIONS</h1>
<pre><code>--add-version, -a        add version numbers to output
--no-add-version         don't add version numbers to output
--core                   include core modules (default)
--no-core                don't include core modules
--cpanfile-file PATH     write a cpanfile combining all three tiers to PATH
--eval-recommends        classify unannotated eval-wrapped deps as recommends, not suggests
--file-list, -L PATH     scan a batch of files listed one per line in PATH
--filter, -f             exclude modules that are this project's own packages
--help, -h               help
--include-require, -i    include 'require'd modules
--no-include-require     don't include required modules
--json, -j               output JSON formatted list
--min-core-version, -m   minimum version of perl to consider core
--path, -p PATH          file to scan (alternative to the positional argument)
--raw, -r                raw output
--recommend-require, -R  classify indented (non-eval) conditional requires as recommends
--recommends-file PATH   write the recommends tier to PATH
--requires-file PATH     write the requires tier to PATH
--separator, -s          separator for output (default: =&gt;)
--suggests-file PATH     write the suggests tier to PATH
--text, -t               output as text (default)
--version, -v            version
</code></pre>
<a id="examples" class="anchor" aria-label="Permalink: Examples" href="#examples"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Examples</h2>
<pre><code>scandeps-static --no-core lib/Some/Module.pm

scandeps-static --json lib/Some/Module.pm
</code></pre>
<p><em>Use the <code>find-requires</code> script included in this distribution to
recurse directories and create dependency files like <code>cpanfile</code></em>.</p>
<a id="option-details" class="anchor" aria-label="Permalink: OPTION DETAILS" href="#option-details"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">OPTION DETAILS</h1>
<ul>
<li>
<p>--add-version, -a, --no-add-version</p>
<p>Add the version number to the dependency list by inspecting the version of
the module in your @INC path.</p>
<p>default: <strong>--add-version</strong></p>
</li>
<li>
<p>--core, -c, --no-core</p>
<p>Include or exclude core modules. See --min-core-version for
description of how core modules are identified.</p>
<p>default: <strong>--core</strong></p>
</li>
<li>
<p>--eval-recommends</p>
<p>Controls how an <code>eval</code>-wrapped <code>require</code>/<code>use</code> is classified when
it carries no explicit <code>## scandeps:</code> annotation (see
<a href="#dependency-tiers">"Dependency Tiers"</a> below). By default such a dependency is
classified as <code>suggests</code>; setting this option flips the
project-wide default to <code>recommends</code> instead. An explicit
annotation always overrides this default regardless of its setting.</p>
<p>default: <strong>--no-eval-recommends</strong> (unannotated evals classify as
<code>suggests</code>)</p>
</li>
<li>
<p>--file-list, -L PATH</p>
<p>Scan a batch of files in a single process instead of one file per
invocation. <code>PATH</code> is a file containing one source file path per
line (relative or absolute); each listed file is scanned in turn and
the results are aggregated. There is currently no way to supply the
list via <code>STDIN</code> - <code>PATH</code> must be a real file.</p>
<p>Batching this way avoids paying Perl's own process-startup cost and
the <code>Module::CoreList</code> module-load cost (non-trivial - loading
<code>Module::CoreList</code> alone is roughly an order of magnitude slower
than a bare <code>perl</code> startup) once per file scanned, which matters a
great deal once a project has more than a handful of source files.</p>
<p>Because more than one JSON document cannot be safely concatenated
into a single valid JSON result, <code>--json</code> is silently ignored
whenever <code>--file-list</code> resolves to more than one file - output is
always text in that case. If the list happens to contain exactly one
file, <code>--json</code> is honored normally.</p>
</li>
<li>
<p>--help, -h</p>
<p>Show usage.</p>
</li>
<li>
<p>--filter, -f</p>
<p>Exclude modules from the output that are themselves <code>package</code>
declarations found somewhere in the files being scanned. Useful with
<code>--file-list</code> to keep a project's own sibling modules from being
reported as external dependencies of each other.</p>
<p>There is no single right default independent of context: a single
file scanned on its own has no sibling in the batch to worry about,
but when <code>--file-list</code> is in use, a same-batch sibling should never
count as an external dependency of another file in the same batch.
So this defaults to <strong>off</strong> for a single file and <strong>on</strong> whenever
<code>--file-list</code> is given - but only when <code>--filter</code>/<code>--no-filter</code>
isn't explicitly set; an explicit setting always wins over this
context-dependent default, in either direction.</p>
</li>
<li>
<p>--requires-file PATH</p>
</li>
<li>
<p>--recommends-file PATH</p>
</li>
<li>
<p>--suggests-file PATH</p>
<p>Write the <code>requires</code>, <code>recommends</code>, or <code>suggests</code> tier
respectively to <code>PATH</code>, in the same format <code>--text</code> would produce
(regardless of whether <code>--json</code> or <code>--raw</code> is also in effect - each
of these is always plain "module version" text, one per line). Any
or all of the three may be given together; each is independent, and
omitting all three changes nothing about existing STDOUT/JSON output.
With <code>--file-list</code>, all files in the batch are scanned once and the
three tiers are populated together from that single pass, rather than
needing a separate scan per tier.</p>
</li>
<li>
<p>--cpanfile-file PATH</p>
<p>Write a single <code>cpanfile</code> to <code>PATH</code>, combining all three tiers in
native <a href="https://metacpan.org/pod/Module%3A%3ACPANfile" rel="nofollow">cpanfile</a> DSL syntax:</p>
<pre><code>  requires 'Module::Name';
  requires 'Module::Name', 'X.YZ';
  recommends 'Module::Name', 'X.YZ';
  suggests 'Module::Name', 'X.YZ';
</code></pre>
<p>A module's version is included only when one was actually detected
(see <code>--add-version</code>) - otherwise the unversioned form is written,
matching <code>cpanfile</code>'s own convention for "any version is acceptable".
A minimum Perl version, if one was declared in the scanned source, is
written the same way any other <code>requires</code> entry would be:
<code>requires 'perl', 'X.YZ';</code> - this is standard <code>cpanfile</code> syntax, not
a special case.</p>
<p>This applies the same filtering as every other output (<code>--core</code> /
<code>--no-core</code>, <code>--filter</code>) uniformly across all three tiers, and
verified to round-trip correctly through <a href="https://metacpan.org/pod/Module%3A%3ACPANfile" rel="nofollow">Module::CPANfile</a> itself.
Independent of <code>--requires-file</code> / <code>--recommends-file</code> /
<code>--suggests-file</code> - any combination of these four file-output options
may be given together in a single scan.</p>
</li>
<li>
<p>--include-require, -i, --no-include-require</p>
<p>Include statements that have <code>Require</code> in them but are not
necessarily on the left edge of the code (possibly in tests).</p>
<p>default: <strong>--include-require</strong></p>
</li>
<li>
<p>--json, -j</p>
<p>Output the dependency list as a JSON encode string. Silently ignored
in favor of text output when combined with <code>--file-list</code> and more
than one file is being scanned - see <a href="#file-list-l-path">"--file-list, -L PATH"</a>.</p>
</li>
<li>
<p>--min-core-version, -m</p>
<p>The minimum version of Perl that is considered core. Use this to
consider some modules non-core if they did not appear until after the
<code>min-core-version</code>.</p>
<p>Core modules are identified using <code>Module::CoreList</code> and comparing
the first release value of the module with the minimum version of
Perl considered as a baseline.  If you're using this module to
identify the dependencies for your script <strong>AND</strong> you know you will be
using a specific version of Perl, then set the <code>min-core-version</code> to
that version of Perl.</p>
<p>Note: this only governs the "not yet in core as of my baseline" case.
A module that was core at some point but has since been <strong>removed</strong>
from core is always treated as non-core, regardless of
<code>min-core-version</code> - there is no way to know which specific Perl an
end user actually has installed, so the only safe answer once a
module has ever been removed is to require it explicitly. See
<a href="#is_core">"is_core"</a> for details.</p>
<p>default: <code>5.8.9</code> (the <code>Module::ScanDeps::Static</code> constructor's
<code>min_core_version</code> option defaults this to the running Perl's version
instead)</p>
</li>
<li>
<p>--path, -p PATH</p>
<p>Path to the file to scan. Equivalent to supplying the path as a bare
positional argument; provided as a named option for clarity in
scripts that build up the command line programmatically. Ignored if
<code>--file-list</code> is also given.</p>
</li>
<li>
<p>--separator, -s</p>
<p>Use the specified string to separate modules and version numbers in formatted output.</p>
<p>default: ' =&gt; '</p>
</li>
<li>
<p>--text, -t</p>
<p>Output the dependency list as a simple text listing of module name and
version in the same manner as <code>scandeps.pl</code>.</p>
<p>default: <strong>--text</strong></p>
</li>
<li>
<p>--raw, -r</p>
<p>Output the list with no quotes separated by a single whitespace
character.</p>
</li>
<li>
<p>--recommend-require</p>
<p>By default, an indented (not left-flushed) <code>require</code> statement that
is not wrapped in <code>eval</code> is either treated as a hard requirement or
dropped entirely, depending on <code>--include-require</code> - see
<a href="#include-require-i-no-include-require">"--include-require, -i, --no-include-require"</a>. Setting this option
instead routes it to the <code>recommends</code> tier (see
<a href="#dependency-tiers">"Dependency Tiers"</a>), regardless of <code>--include-require</code>'s setting.
Off by default - every existing case behaves exactly as it did before
this option existed.</p>
<p>default: <strong>--no-recommend-require</strong></p>
</li>
</ul>
<a id="what-is-a-dependency" class="anchor" aria-label="Permalink: WHAT IS A DEPENDENCY?" href="#what-is-a-dependency"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">WHAT IS A DEPENDENCY?</h1>
<p>For the purposes of this module, dependencies are identified by
looking for Perl modules and other Perl artifacts declared using
<code>use</code>, <code>require</code>, <code>parent</code>, or <code>base</code>. The script will also
consider Moo/Role::Tiny modules included using <code>with</code>, and Moose
inheritance declared using <code>extends</code> - both are treated identically
to <code>use parent</code>/<code>use base</code>.</p>
<p>If the module contains a <code>require</code> statement, by default the
<code>require</code> must be flush up against the left edge of your script
without any whitespace between it and beginning of the line.  This is
the default behavior to avoid identifying <code>require</code> statements that
are embedded in <code>if</code> statements. If you want to include all of
the targets of <code>require</code> statements as dependencies, set the
<code>include-require</code> option to a true value.</p>
<a id="dependency-tiers" class="anchor" aria-label="Permalink: Dependency Tiers" href="#dependency-tiers"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Dependency Tiers</h2>
<p>Every dependency found is classified into one of three tiers,
matching the <code>requires</code>/<code>recommends</code>/<code>suggests</code> relationship types
defined by <a href="https://metacpan.org/pod/CPAN%3A%3AMeta%3A%3ASpec" rel="nofollow">CPAN::Meta::Spec</a>:</p>
<ul>
<li>
<p>requires</p>
<p>A bare, unconditional <code>use</code> or <code>require</code>, or a <code>with</code>/<code>extends</code>/
<code>parent</code>/<code>base</code> declaration. Nothing in the surrounding code
suggests the author considered this module might be absent.</p>
</li>
<li>
<p>recommends</p>
<p>A dependency the author explicitly guarded against being absent (see
<a href="#structural-classification">"Structural Classification"</a> below), where the author's own
annotation or this module's default judges the guard to matter more
than a mere enhancement - see <a href="#the-scandeps-annotation">"The <code>## scandeps:</code> Annotation"</a>.</p>
</li>
<li>
<p>suggests</p>
<p>The weaker of the two soft tiers - a guarded dependency judged to be
a genuine enhancement rather than something most users would need.</p>
</li>
</ul>
<p>This module makes <strong>no attempt</strong> to infer which of <code>recommends</code> or
<code>suggests</code> is correct by analyzing what a guarded dependency's
failure path actually does (for example, whether it <code>die</code>s or
degrades gracefully). That was a deliberate decision, not an
oversight: whether a dependency is merely nice-to-have or genuinely
important is a judgment about a project's own design, not a fact
recoverable from code structure - the same code shape (<code>eval { require Foo }</code>) is written identically by an author who considers
<code>Foo</code> essential and one who considers it optional. Guessing at that
judgment and presenting the guess as if it were derived from parsing
would be dishonest about what static analysis can actually know. Use
the annotation below to state it explicitly instead.</p>
<a id="structural-classification" class="anchor" aria-label="Permalink: Structural Classification" href="#structural-classification"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Structural Classification</h2>
<p>Only a genuinely unconditional <code>use</code>/<code>require</code> is ever classified
as <code>requires</code>. Anything the author has structurally guarded is
pulled into one of the soft tiers:</p>
<ul>
<li>
<code>eval { require/use Foo }</code> or <code>eval "require/use Foo"</code>, in
any form - single-line, multi-line, with or without a trailing
<code>or die</code>/<code>or do { }</code> - is classified as <code>suggests</code> by default, or
<code>recommends</code> if <code>--eval-recommends</code> is set (see
<a href="#eval-recommends">"--eval-recommends"</a>). Either default can be overridden per-instance
with an explicit annotation - see below.</li>
<li>An indented (not left-flushed), non-<code>eval</code> <code>require</code> - for
example inside a bare <code>if</code> block - is treated as a hard requirement
by default (or dropped entirely if <code>--include-require</code> is off), the
same as it always has been. Set <code>--recommend-require</code> to instead
route these to <code>recommends</code>. See
<a href="#recommend-require">"--recommend-require"</a>.</li>
</ul>
<div class="markdown-heading"><h2 class="heading-element">The <code>## scandeps:</code> Annotation</h2><a id="the--scandeps-annotation" class="anchor" aria-label="Permalink: The ## scandeps: Annotation" href="#the--scandeps-annotation"><span aria-hidden="true" class="octicon octicon-link"></span></a></div>
<p>Because the <code>recommends</code> vs. <code>suggests</code> distinction is a judgment
call this module deliberately does not try to infer (see
<a href="#dependency-tiers">"Dependency Tiers"</a>), an author can state that judgment explicitly
with a comment:</p>
<pre><code>eval { require Foo::Bar; };  ## scandeps: recommends

eval { require Foo::Bar; 1; } or die $@;  ## scandeps: suggests

eval {
    require Foo::Bar;
    1;
} or do {
    warn "Foo::Bar unavailable, continuing without it\n";
};  ## scandeps: recommends
</code></pre>
<p>The annotation must appear immediately after the semicolon that ends
the whole statement - not the eval block's own closing brace, but
wherever the statement as a whole actually terminates, which may be
after a trailing <code>or die ...;</code> or <code>or do { ... };</code>. An explicit
annotation always overrides both this module's structural default and
the <code>--eval-recommends</code> setting.</p>
<p>This annotation is only recognized on the brace form of <code>eval</code>
(<code>eval { ... }</code>). It is not supported on the string form
(<code>eval "..."</code>) - anyone still writing string <code>eval</code> for this
purpose is not expected to participate in this feature.</p>
<a id="conflicting-classifications" class="anchor" aria-label="Permalink: Conflicting Classifications" href="#conflicting-classifications"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Conflicting Classifications</h2>
<p>A single module can legitimately be a hard requirement in one file
and guarded in another - both facts can be true of the same project
at once. When that happens, this module does not silently pick a
winner: it emits a warning to <code>STDERR</code> naming the conflicting
module, and leaves <code>require</code>, <code>recommends</code>, and <code>suggests</code> exactly
as found. Resolving the contradiction belongs in the project's own
source, not in this tool - either the guarded usage no longer needs
to hedge, since the module is guaranteed to be present anyway because
of the other, unconditional usage, or the unconditional usage should
really be conditional too.</p>
<p>The same warning fires if a module appears in both <code>recommends</code> and
<code>suggests</code> at once.</p>
<a id="self-referential-modules" class="anchor" aria-label="Permalink: Self-Referential Modules" href="#self-referential-modules"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Self-Referential Modules</h2>
<p>When scanning a whole project (typically via <code>--file-list</code>), a
module in one file may <code>use</code> a sibling module declared with
<code>package</code> in another file in the same project - not a real external
dependency at all. <code>--filter</code> excludes any module name that appears
anywhere in the batch as a <code>package</code> declaration; see
<a href="#filter-f">"--filter, -f"</a> for its (context-dependent) default.</p>
<a id="dynamic-module-loading" class="anchor" aria-label="Permalink: Dynamic Module Loading" href="#dynamic-module-loading"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Dynamic Module Loading</h2>
<p>This module performs <em>static</em> analysis: it reads source as text and
looks for recognizable patterns. It cannot execute your code, and so
cannot know the value of a variable at runtime. A module loaded via a
computed name - for example <code>Module::Load::load($module)</code> where
<code>$module</code> is a variable - is invisible to this scanner and will
never appear in <code>require</code>, <code>recommends</code>, or <code>suggests</code>, no matter
how the code is structured.</p>
<p>This is a real and legitimate use case for modules like
<a href="https://metacpan.org/pod/Module%3A%3ALoad" rel="nofollow">Module::Load</a>, <a href="https://metacpan.org/pod/Module%3A%3ARuntime" rel="nofollow">Module::Runtime</a>, and <a href="https://metacpan.org/pod/Class%3A%3ALoad" rel="nofollow">Class::Load</a>: loading a
plugin or driver whose name genuinely isn't known until the program
runs. For that use case, invisibility to any static scanner is an
unavoidable trade-off, not a defect in this module.</p>
<p>It becomes an antipattern, though, when one of these modules is
called with a name that <em>is</em> known at write time:</p>
<pre><code>Module::Load::load('Term::ANSIColor');
</code></pre>
<p>The module name here is a literal string, not runtime data - a plain</p>
<pre><code>eval { require Term::ANSIColor; };
</code></pre>
<p>would behave identically at runtime, while remaining visible to this
scanner and annotatable with <code>## scandeps:</code>. Reach for
<code>Module::Load</code> and similar modules only when the module name is
genuinely computed at runtime - for loading plugins or other modules
that are already known to be part of your project's own architecture
- not as a general-purpose substitute for <code>require</code>.</p>
<p>Do not expect this scanner to understand dynamic module loading. If a
project genuinely depends on a module that can only be discovered at
runtime, that dependency needs to be declared by hand (for example, in
a <code>cpanfile</code> or <code>buildspec.yml</code>) - this module cannot discover it.</p>
<div class="markdown-heading"><h1 class="heading-element">MINOR IMPROVEMENTS TO <code>perl.req</code>
</h1><a id="minor-improvements-to-perlreq" class="anchor" aria-label="Permalink: MINOR IMPROVEMENTS TO perl.req" href="#minor-improvements-to-perlreq"><span aria-hidden="true" class="octicon octicon-link"></span></a></div>
<ul>
<li>
<p>Allow detection of <code>require</code> not at beginning of line.</p>
<p>Use the <code>--include-require</code> to expand the definition of a dependency
to any module or Perl script that is the argument of the <code>require</code>
statement.</p>
</li>
<li>
<p>Allow detection of the <code>parent</code>, <code>base</code> statements use of curly braces.</p>
<p>The regular expression and algorithm in <code>parse</code> has been enhanced to
detect the use of curly braces in <code>use</code> or <code>parent</code> declarations.</p>
</li>
<li>
<p>Exclude core modules.</p>
<p>Use the <code>--no-core</code> option to ignore core modules.</p>
</li>
<li>
<p>Add the current version of an installed module if the version
is not explicitly specified.</p>
</li>
</ul>
<a id="caveats" class="anchor" aria-label="Permalink: CAVEATS" href="#caveats"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">CAVEATS</h1>
<p>There are still many situations (including multi-line statements) that
may prevent this module from properly identifying a dependency. As
always, YMMV.</p>
<a id="methods-and-subroutines" class="anchor" aria-label="Permalink: METHODS AND SUBROUTINES" href="#methods-and-subroutines"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">METHODS AND SUBROUTINES</h1>
<a id="new" class="anchor" aria-label="Permalink: new" href="#new"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">new</h2>
<pre><code>new(options)
</code></pre>
<p>Returns a <code>Module::ScanDeps::Static</code> object.</p>
<a id="options-1" class="anchor" aria-label="Permalink: Options" href="#options-1"><span aria-hidden="true" class="octicon octicon-link"></span></a><h3 class="heading-element">Options</h3>
<ul>
<li>
<p>path</p>
<p>Path to a file to scan. When set, <code>parse()</code> opens this file and reads
from it.</p>
<p>default: <strong>none</strong> (if neither <code>path</code> nor <code>handle</code> is given, <code>parse()</code>
reads from <code>STDIN</code>)</p>
</li>
<li>
<p>handle</p>
<p>An open filehandle (or any <code>IO::Handle</code>-like object) to read from
instead of a file. Ignored when <code>path</code> is set.</p>
<p>default: <strong>none</strong></p>
</li>
<li>
<p>core</p>
<p>Boolean value that determines whether to include core modules as part
of the dependency listing.</p>
<p>default: <strong>true</strong></p>
</li>
<li>
<p>include_require</p>
<p>Boolean value that determines whether to consider <code>require</code>
statements that are not left-aligned to be considered dependencies.</p>
<p>default: <strong>false</strong> (the <code>scandeps-static.pl</code> CLI defaults this to true)</p>
</li>
<li>
<p>add_version</p>
<p>Boolean value that determines whether to include the version of the
module currently installed if there is no version specified.</p>
<p>default: <strong>true</strong></p>
</li>
<li>
<p>min_core_version</p>
<p>The minimum version of Perl which will be used to decide if a module
is included in Perl core. See <code>is_core</code> and the <code>--min-core-version</code>
option for details.</p>
<p>default: <strong>the running Perl's version</strong> (<code>$PERL_VERSION</code>). The
<code>scandeps-static.pl</code> CLI defaults this to <code>5.8.9</code>.</p>
</li>
<li>
<p>json</p>
<p>Boolean value that indicates output should be in JSON format.</p>
<p>default: <strong>false</strong></p>
</li>
<li>
<p>text</p>
<p>Boolean value that indicates output should be in the same format as
<code>scandeps.pl</code>. This is the default output format for <code>get_dependencies</code>
when neither <code>json</code> nor <code>raw</code> is set.</p>
<p>default: <strong>true</strong></p>
</li>
<li>
<p>raw</p>
<p>Boolean value that indicates output should be in raw format
(module version).</p>
<p>default: <strong>false</strong></p>
</li>
<li>
<p>separator</p>
<p>Character string used to separate the module name from the version in
text output.</p>
<p>default: <strong>none</strong> from the constructor; <code>format_text</code> falls back to a
single space. The <code>scandeps-static.pl</code> CLI sets this to <code> =</code> &gt;.</p>
</li>
</ul>
<a id="get_require" class="anchor" aria-label="Permalink: get_require" href="#get_require"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_require</h2>
<p>After calling the <code>parse()</code> method, call this method to retrieve a
hash containing the dependencies and (potentially) their version
numbers.</p>
<pre><code>$scanner-&gt;parse;
my $requires = $scanner-&gt;get_require;
</code></pre>
<a id="get_perlreq" class="anchor" aria-label="Permalink: get_perlreq" href="#get_perlreq"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_perlreq</h2>
<p>Returns a hash ref of Perl version requirements discovered while
parsing (keyed by <code>'perl'</code>). Populated for <code>use 5.010;</code> /
<code>require 5.010;</code> style statements. Pair with <code>get_require</code>.</p>
<pre><code>$scanner-&gt;parse;
my $perlreq = $scanner-&gt;get_perlreq;  # { perl =&gt; '5.010', ... }
</code></pre>
<a id="parse" class="anchor" aria-label="Permalink: parse" href="#parse"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">parse</h2>
<ul>
<li>
<p>parse a file</p>
<pre><code>  my @dependencies = Module::ScanDeps::Static-&gt;new({ path =&gt; $path })-&gt;parse;
</code></pre>
</li>
<li>
<p>parse from file handle</p>
<pre><code>  my @dependencies = Module::ScanDeps::Static-&gt;new({ handle =&gt; $path })-&gt;parse;
</code></pre>
</li>
<li>
<p>parse STDIN</p>
<pre><code>  my @dependencies = Module::ScanDeps::Static-&gt;new-&gt;parse(\$script);
</code></pre>
</li>
<li>
<p>parse string</p>
<pre><code>  my @dependencies = parse(\$script);
</code></pre>
</li>
</ul>
<p>Scans the specified input and returns a list of Perl module dependencies.</p>
<p>Use the <code>get_dependencies</code> method to retrieve the dependencies as a
formatted string or as a list of dependency objects. Use the
<code>get_require</code> and <code>get_perlreq</code> methods to retrieve dependencies as
a list of hash refs.</p>
<pre><code>my $scanner = Module::ScanDeps::Static-&gt;new({ path =&gt; 'my-script.pl' });
my @dependencies = $scanner-&gt;parse;
</code></pre>
<a id="get_dependencies" class="anchor" aria-label="Permalink: get_dependencies" href="#get_dependencies"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_dependencies</h2>
<p>Returns a formatted list of dependencies or a list of dependency objects.</p>
<p>As JSON:</p>
<pre><code>print $scanner-&gt;get_dependencies( format =&gt; 'json' )

[
  {
   "name" : "Module::Name",
   "version" : "version"
  },
  ...
]
</code></pre>
<p>..or as text:</p>
<pre><code>print $scanner-&gt;get_dependencies( format =&gt; 'text' )

Module::Name =&gt; version
...
</code></pre>
<p>In scalar context in the absence of an argument returns a JSON
formatted string. In list context will return a list of hashes that
contain the keys "name" and "version" for each dependency.</p>
<p>Note: this context-sensitivity only applies when none of <code>json</code>,
<code>text</code>, or <code>raw</code> is set (or when <code>format =&gt; 'json'</code> /
<code>format =&gt; 'text'</code> is passed explicitly). If the <code>json</code> option is
true, <code>get_dependencies</code> always returns a scalar JSON string, even
when called in list context.</p>
<a id="format_text" class="anchor" aria-label="Permalink: format_text" href="#format_text"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">format_text</h2>
<pre><code>$scanner-&gt;parse;
print $scanner-&gt;format_text;
</code></pre>
<p>Returns the dependency list as a formatted text string, one module per
line, honoring the <code>separator</code> and <code>raw</code> options. Core modules are
omitted when <code>core</code> is false.</p>
<a id="format_json" class="anchor" aria-label="Permalink: format_json" href="#format_json"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">format_json</h2>
<pre><code>my $json     = $scanner-&gt;format_json;   # scalar context
my @requires = $scanner-&gt;format_json;   # list context
</code></pre>
<p>In scalar context returns a pretty-printed JSON string; in list context
returns a list of hash refs of the form <code>{ name =&gt; ..., version =&gt; ... }</code>. Core modules are omitted when <code>core</code> is false. Any arguments
are treated as a seed list and prepended to the results.</p>
<a id="format_cpanfile" class="anchor" aria-label="Permalink: format_cpanfile" href="#format_cpanfile"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">format_cpanfile</h2>
<pre><code>$scanner-&gt;parse;
print $scanner-&gt;format_cpanfile;
</code></pre>
<p>Returns a single <code>cpanfile</code> (see <a href="https://metacpan.org/pod/Module%3A%3ACPANfile" rel="nofollow">Module::CPANfile</a>) combining all
three tiers, using native <code>requires</code>/<code>recommends</code>/<code>suggests</code> DSL
syntax. Versions are included only where actually detected (see
<code>add_version</code>); otherwise the unversioned form is written. Applies
the same <code>core</code>/<code>filter</code> filtering as <code>format_json</code>, since it's
built on top of it rather than duplicating that logic.</p>
<a id="is_core" class="anchor" aria-label="Permalink: is_core" href="#is_core"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">is_core</h2>
<pre><code>my $bool = $scanner-&gt;is_core($module);
my $bool = $scanner-&gt;is_core("$module $version");
</code></pre>
<p>Returns true if <code>$module</code> is considered core. A module is core when
<code>Module::CoreList</code> reports its first release at or before
<code>min_core_version</code> <strong>and</strong> the module has never been removed from
core at any point in its history.</p>
<p>A module that was core at some earlier Perl but has since been
removed is always treated as non-core, regardless of how
<code>min_core_version</code> compares to the version it was removed at. There
is no way to know which Perl an end user actually has installed - a
version comparison against a single reference point only protects
against removals that happen to fall on one particular side of it, so
the only safe answer once a module has ever been removed is to always
require it explicitly.</p>
<a id="min_core_version" class="anchor" aria-label="Permalink: min_core_version" href="#min_core_version"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">min_core_version</h2>
<pre><code>my $numified = $scanner-&gt;min_core_version;
</code></pre>
<p>Returns the <code>min_core_version</code> option numified via <code>version</code> (e.g.
<code>5.008009</code>) for comparison inside <code>is_core</code>. Note this is distinct
from the generated <code>get_min_core_version</code> accessor, which returns the
raw stored value.</p>
<a id="get_module_version" class="anchor" aria-label="Permalink: get_module_version" href="#get_module_version"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_module_version</h2>
<pre><code>my $info = $scanner-&gt;get_module_version($module, @include_path);
</code></pre>
<p>Returns a hash ref describing <code>$module</code>:</p>
<pre><code>{ module =&gt; ..., version =&gt; ..., path =&gt; ..., file =&gt; ... }
</code></pre>
<p>Searches <code>@include_path</code> (defaulting to <code>@INC</code>) for the module and
extracts its version via <code>ExtUtils::MM-</code>parse_version&gt;. If <code>$module</code>
already carries a version (<code>"Foo::Bar 1.23"</code>), that version is returned
without a filesystem lookup.</p>
<a id="add_require" class="anchor" aria-label="Permalink: add_require" href="#add_require"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">add_require</h2>
<pre><code>$scanner-&gt;add_require($module);
$scanner-&gt;add_require($module, $version);
</code></pre>
<p>Registers <code>$module</code> as a dependency, optionally with <code>$version</code>. When
no version is supplied and the <code>add_version</code> option is true, the
installed version is looked up. Retains the higher of two versions if
the module is added more than once. Returns <code>$self</code>.</p>
<a id="to_rpm" class="anchor" aria-label="Permalink: to_rpm" href="#to_rpm"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">to_rpm</h2>
<pre><code>my $deps = $scanner-&gt;to_rpm;
</code></pre>
<p>Returns the dependency list as RPM-style requirement expressions
(<code>perl(Module) &gt;= version</code>, plus <code>perl &gt;= version</code> for any
Perl version requirement). Core modules are omitted when <code>core</code> is
false.</p>
<a id="version" class="anchor" aria-label="Permalink: VERSION" href="#version"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">VERSION</h1>
<p>This documentation refers to version 1.9.2</p>
<a id="author" class="anchor" aria-label="Permalink: AUTHOR" href="#author"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">AUTHOR</h1>
<p>This module is largely a lift and drop of Ken Este's <code>perl.req</code> script
lifted from rpm build tools.</p>
<p>Ken Estes Mail.com <a href="mailto:kestes@staff.mail.com">kestes@staff.mail.com</a></p>
<p>The method <code>parse</code> is a cleaned up version of <code>process_file</code> from the
same script.</p>
<p>Rob Lauer - <a href="mailto:bigfoot@cpan.org">bigfoot@cpan.org</a></p>
<a id="license" class="anchor" aria-label="Permalink: LICENSE" href="#license"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">LICENSE</h1>
<p>This statement was lifted directly from <code>perl.req</code>...</p>
<blockquote>
<p><em>The entire code base may be distributed under the terms of the
GNU General Public License (GPL), which appears immediately below.
Alternatively, all of the source code in the lib subdirectory of the
RPM source code distribution as well as any code derived from that
code may instead be distributed under the GNU Library General Public
License (LGPL), at the choice of the distributor. The complete text of
the LGPL appears at the bottom of this file.</em></p>
<p><em>This alternatively is allowed to enable applications to be linked
against the RPM library (commonly called librpm) without forcing
such applications to be distributed under the GPL.</em></p>
<p><em>Any questions regarding the licensing of RPM should be addressed to
Erik Troan &lt;<a href="mailto:ewt@redhat.com">ewt@redhat.com</a></em>.&gt;</p>
</blockquote>
