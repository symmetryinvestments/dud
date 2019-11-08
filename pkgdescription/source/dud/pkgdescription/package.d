module dud.pkgdescription;

import std.typecons : Nullable;

public import dud.pkgdescription.path;
public import dud.pkgdescription.versionspecifier;
public import dud.pkgdescription.udas;
public import dud.pkgdescription.json;
public import dud.pkgdescription.sdl;
public import dud.pkgdescription.platform;

import dud.semver;

@safe pure:

enum TargetType {
	autodetect,
	none,
	executable,
	library,
	sourceLibrary,
	dynamicLibrary,
	staticLibrary,
	object
}

/**
	Describes the build settings and meta data of a single package.

	This structure contains the effective build settings and dependencies for
	the selected build platform. This structure is most useful for displaying
	information about a package in an IDE. Use `TargetDescription` instead when
	writing a build-tool.
*/
struct PackageDescription {
@safe pure:
	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToSName)("")
	string name; /// Qualified name of the package

	@JSON!(jGetSemVer, semVerToJ)("version")
	@SDL!(sGetSemVer, semVerToS)("version")
	SemVer version_; /// Version of the package

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string description;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string homepage;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] authors;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string copyright;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string license;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string systemDependencies;

	@JSON!(jGetDependencies, dependenciesToJ)("")
	@SDL!(sGetDependencies, dependenciesToS)("dependency")
	Dependency[] dependencies;

	@JSON!(jGetTargetType, targetTypeToJ)("")
	@SDL!(sGetTargetType, targetTypeToS)("")
	TargetType targetType;

	@JSON!(jGetPath, pathToJ)("")
	@SDL!(sGetPath, pathToS)("")
	Path targetPath;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("")
	String targetName;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("")
	String targetFileName;

	@JSON!(jGetPath, pathToJ)("")
	@SDL!(sGetPath, pathToS)("")
	Path workingDirectory;

	@JSON!(jGetPath, pathToJ)("")
	@SDL!(sGetPath, pathToS)("")
	Path mainSourceFile;

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings dflags; /// Flags passed to the D compiler

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings lflags; /// Flags passed to the linker

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings libs; /// Librariy names to link against (typically using "-l<name>")

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths copyFiles; /// Files to copy to the target directory

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths extraDependencyFiles; /// Files to check for rebuild dub project

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings versions; /// D version identifiers to set

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings debugVersions; /// D debug version identifiers to set

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths importPaths;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths sourcePaths;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths sourceFiles;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths excludedSourceFiles;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths stringImportPaths;

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings preGenerateCommands; /// commands executed before creating the description

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings postGenerateCommands; /// commands executed after creating the description

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings preBuildCommands; /// Commands to execute prior to every build

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings postBuildCommands; /// Commands to execute after every build

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings preRunCommands; /// Commands to execute prior to every run

	@JSON!(jGetStringsPlatform, stringsPlatformToJ)("")
	@SDL!(sGetStringsPlatform, stringsPlatformToS)("")
	Strings postRunCommands; /// Commands to execute after every run

	@JSON!(jGetPackageDescriptions, packageDescriptionsToJ)("")
	@SDL!(sGetPackageDescriptions, configurationsToS)("configuration")
	PackageDescription[] configurations;

	@JSON!(jGetStrings, stringsToJ)("-ddoxFilterArgs")
	@SDL!(sGetStrings, stringsToS)("x:ddoxFilterArgs")
	string[] ddoxFilterArgs;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:debugVersionFilters")
	string[] debugVersionFilters;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("-ddoxTool")
	@SDL!(sGetStringPlatform, stringPlatformToS)("x:ddoxTool")
	String ddoxTool;

	@JSON!(jGetSubPackages, subPackagesToJ)("")
	@SDL!(sGetSubPackage, subPackagesToS)("subPackage")
	SubPackage[] subPackages;

	@JSON!(jGetBuildRequirements, buildRequirementsToJ)("")
	@SDL!(sGetBuildRequirements, buildRequirementsToS)("")
	BuildRequirement[] buildRequirements;

	@JSON!(jGetStringAA, stringAAToJ)("")
	@SDL!(sGetSubConfig, subConfigsToS)("subConfiguration")
	SubConfigs subConfigurations;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:versionFilters")
	string[] versionFilters;

	@JSON!(jGetBuildTypes, buildTypesToJ)("")
	@SDL!(sGetBuildTypes, buildTypesToS)("buildType")
	BuildType[] buildTypes;

	@JSON!(jGetBuildOptions, buildOptionsToJ)("")
	@SDL!(sGetBuildOptions, buildOptionsToS)("")
	BuildOptions buildOptions;

	@JSON!(jGetPlatforms, platformsToJ)("")
	@SDL!(sGetPlatforms, platformsToS)("")
	Platform[] platforms;

	bool opEquals(const PackageDescription other) const {
		import dud.pkgdescription.compare : areEqual;
		return areEqual(this, other);
	}
}

struct BuildOptions {
	BuildOption[][immutable(Platform[])] platforms;
	BuildOption[] unspecifiedPlatform;
}

enum BuildOption {
	/// Compile in debug mode (enables contracts) -debug
	debugMode,
	/// Compile in release mode (disables assertions and bounds checks) -release
	releaseMode,
	/// Enable code coverage analysis -cov
	coverage,
	/// Enable symbolic debug information -g
	debugInfo,
	/// Enable symbolic debug information in C compatible form -gc
	debugInfoC,
	/// Always generate a stack frame -gs
	alwaysStackFrame,
	/// Perform stack stomping -gx
	stackStomping,
	/// Perform function inlining -inline
	inline,
	/// Disable all bounds checking -boundscheck=off
	noBoundsCheck,
	/// Enable optimizations -O
	optimize,
	/// Emit profiling code -profile
	profile,
	/// Emit GC profiling information -profile=gc
	profileGC,
	/// Compile unit tests -unittest
	unittests,
	/// Verbose compiler output -v
	verbose,
	/// Ignores unknown pragmas during compilation -ignore
	ignoreUnknownPragmas,
	/// Don't generate object files -o-
	syntaxOnly,
	/** Enable warnings, enabled by default
	(use , buildRequirements,  to control this setting) -wi
	*/
	warnings,
	/** Treat warnings as errors
	(use , buildRequirements,  to control this setting) -w
	*/
	warningsAsErrors,
	/** Do not warn about using deprecated features
	(use , buildRequirements,  to control this setting) -d
	*/
	ignoreDeprecations,
	/** Warn about using deprecated features, enabled by default
	(use , buildRequirements,  to control this setting) -dw
	*/
	deprecationWarnings,
	/** Stop compilation upon usage of deprecated features
	(use , buildRequirements,  to control this setting) -de
	*/
	deprecationErrors,
	/// Enforce property syntax - deprecated -property
	property,
	/// Compile in betterC mode -betterC
	betterC,
}

struct SubConfigs {
	string[string][immutable(Platform[])] configs;
	string[string] unspecifiedPlatform;
}

struct BuildType {
	string name;
	Platform[] platforms;
	PackageDescription pkg;
}

enum BuildRequirement {
	allowWarnings,
	silenceWarnings,
	disallowDeprecations,
	silenceDeprecations,
	disallowInlining,
	disallowOptimization,
	requireBoundsCheck,
	requireContracts,
	relaxProperties,
	noDefaultFlags,
}

struct SubPackage {
	Path path;
	Nullable!PackageDescription inlinePkg;
}

struct Dependency {
@safe pure:
	import std.typecons : Nullable;
	string name;
	Nullable!VersionSpecifier version_;
	UnprocessedPath path;
	Nullable!bool optional;
	Nullable!bool default_;
	Platform[] platforms;

	bool opEqual()(auto ref const Dependency other) const {
		return areEqual(this, other);
	}
}

struct StringPlatform {
	string str;
	Platform[] platforms;
}

struct String {
@safe pure:
	StringPlatform[] platforms;
}

struct StringsPlatform {
	string[] strs;
	Platform[] platforms;
}

struct Strings {
	StringsPlatform[] platforms;
}
