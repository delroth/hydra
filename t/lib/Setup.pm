package Setup;

use strict;
use warnings;
use Exporter;
use Test::PostgreSQL;
use File::Temp;
use File::Path qw(make_path);
use File::Basename;
use Cwd qw(abs_path getcwd);

our @ISA = qw(Exporter);
our @EXPORT = qw(test_context test_init hydra_setup write_file nrBuildsForJobset queuedBuildsForJobset
                 nrQueuedBuildsForJobset createBaseJobset createJobsetWithOneInput
                 evalSucceeds runBuild sendNotifications updateRepository
                 captureStdoutStderr);

# Set up the environment for running tests.
#
# See HydraTestContext::new for documentation
sub test_context {
    require HydraTestContext;
    return HydraTestContext->new(@_);
}

# Set up the environment for running tests.
#
# See HydraTestContext::new for documentation
sub test_init {
    require HydraTestContext;
    my $ctx = HydraTestContext->new(@_);

    return (
        context => $ctx,
        tmpdir => $ctx->tmpdir,
        testdir => $ctx->testdir,
        jobsdir => $ctx->jobsdir
    )
}

sub write_file {
    my ($path, $text) = @_;
    open(my $fh, '>', $path) or die "Could not open file '$path' $!";
    print $fh $text || "";
    close $fh;
}

sub captureStdoutStderr {
    # "Lazy"-load Hydra::Helper::Nix to avoid the compile-time
    # import of Hydra::Model::DB. Early loading of the DB class
    # causes fixation of the DSN, and we need to fixate it after
    # the temporary DB is setup.
    require Hydra::Helper::Nix;
    return Hydra::Helper::Nix::captureStdoutStderr(@_)
}

sub hydra_setup {
    my ($db) = @_;
    $db->resultset('Users')->create({ username => "root", emailaddress => 'root@invalid.org', password => '' });
}

sub nrBuildsForJobset {
    my ($jobset) = @_;
    return $jobset->builds->search({},{})->count ;
}

sub queuedBuildsForJobset {
    my ($jobset) = @_;
    return $jobset->builds->search({finished => 0});
}

sub nrQueuedBuildsForJobset {
    my ($jobset) = @_;
    return queuedBuildsForJobset($jobset)->count ;
}

sub createBaseJobset {
    my ($jobsetName, $nixexprpath, $jobspath) = @_;

    my $db = Hydra::Model::DB->new;
    my $project = $db->resultset('Projects')->update_or_create({name => "tests", displayname => "", owner => "root"});
    my $jobset = $project->jobsets->create({name => $jobsetName, nixexprinput => "jobs", nixexprpath => $nixexprpath, emailoverride => ""});

    my $jobsetinput;
    my $jobsetinputals;

    $jobsetinput = $jobset->jobsetinputs->create({name => "jobs", type => "path"});
    $jobsetinputals = $jobsetinput->jobsetinputalts->create({altnr => 0, value => $jobspath});

    return $jobset;
}

sub createJobsetWithOneInput {
    my ($jobsetName, $nixexprpath, $name, $type, $uri, $jobspath) = @_;
    my $jobset = createBaseJobset($jobsetName, $nixexprpath, $jobspath);

    my $jobsetinput;
    my $jobsetinputals;

    $jobsetinput = $jobset->jobsetinputs->create({name => $name, type => $type});
    $jobsetinputals = $jobsetinput->jobsetinputalts->create({altnr => 0, value => $uri});

    return $jobset;
}

sub evalSucceeds {
    my ($jobset) = @_;
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ("hydra-eval-jobset", $jobset->project->name, $jobset->name));
    $jobset->discard_changes;  # refresh from DB
    chomp $stdout; chomp $stderr;
    print STDERR "Evaluation errors for jobset ".$jobset->project->name.":".$jobset->name.": \n".$jobset->errormsg."\n" if $jobset->errormsg;
    print STDERR "STDOUT: $stdout\n" if $stdout ne "";
    print STDERR "STDERR: $stderr\n" if $stderr ne "";
    return !$res;
}

sub runBuild {
    my ($build) = @_;
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ("hydra-queue-runner", "-vvvv", "--build-one", $build->id));
    if ($res) {
        print STDERR "Queue runner stdout: $stdout\n" if $stdout ne "";
        print STDERR "Queue runner stderr: $stderr\n" if $stderr ne "";
    }
    return !$res;
}

sub sendNotifications() {
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ("hydra-notify", "--queued-only"));
    if ($res) {
        print STDERR "hydra notify stdout: $stdout\n" if $stdout ne "";
        print STDERR "hydra notify stderr: $stderr\n" if $stderr ne "";
    }
    return !$res;
}

sub updateRepository {
    my ($scm, $update, $scratchdir) = @_;
    my $curdir = getcwd;
    chdir "$scratchdir";
    my ($res, $stdout, $stderr) = captureStdoutStderr(60, ($update, $scm));
    chdir "$curdir";
    die "unexpected update error with $scm: $stderr\n" if $res;
    my ($message, $loop, $status) = $stdout =~ m/::(.*) -- (.*) -- (.*)::/;
    print STDOUT "Update $scm repository: $message\n";
    return ($loop eq "continue", $status eq "updated");
}

1;
