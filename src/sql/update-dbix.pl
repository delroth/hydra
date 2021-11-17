use Cwd;
use strict;
use warnings;

die "$0: dbi connection string required \n" if scalar @ARGV != 1;

make_schema_at("Hydra::Schema", {
    naming => { ALL => "v5" },
    relationships => 1,
    use_namespaces => 1,
    overwrite_modifications => 1,
    moniker_map => {
        "aggregateconstituents" => "AggregateConstituents",
        "buildinputs" => "BuildInputs",
        "buildmetrics" => "BuildMetrics",
        "buildoutputs" => "BuildOutputs",
        "buildproducts" => "BuildProducts",
        "builds" => "Builds",
        "buildstepoutputs" => "BuildStepOutputs",
        "buildsteps" => "BuildSteps",
        "cachedbazaarinputs" => "CachedBazaarInputs",
        "cachedcvsinputs" => "CachedCVSInputs",
        "cacheddarcsinputs" => "CachedDarcsInputs",
        "cachedgitinputs" => "CachedGitInputs",
        "cachedhginputs" => "CachedHgInputs",
        "cachedpathinputs" => "CachedPathInputs",
        "cachedsubversioninputs" => "CachedSubversionInputs",
        "evaluationerrors" => "EvaluationErrors",
        "failedpaths" => "FailedPaths",
        "jobsetevalinputs" => "JobsetEvalInputs",
        "jobsetevalmembers" => "JobsetEvalMembers",
        "jobsetevals" => "JobsetEvals",
        "jobsetinputalts" => "JobsetInputAlts",
        "jobsetinputs" => "JobsetInputs",
        "jobsetrenames" => "JobsetRenames",
        "jobsets" => "Jobsets",
        "newsitems" => "NewsItems",
        "nrbuilds" => "NrBuilds",
        "projectmembers" => "ProjectMembers",
        "projects" => "Projects",
        "runcommandlogs" => "RunCommandLogs",
        "schemaversion" => "SchemaVersion",
        "starredjobs" => "StarredJobs",
        "systemstatus" => "SystemStatus",
        "taskretries" => "TaskRetries",
        "urirevmapper" => "UriRevMapper",
        "userroles" => "UserRoles",
        "users" => "Users",
    } , #sub { return "$_"; },
    components => [ "+Hydra::Component::ToJSON" ],
    rel_name_map => { buildsteps_builds => "buildsteps" }
}, [$ARGV[0]]);
