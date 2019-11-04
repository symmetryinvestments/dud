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

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("")
	String workingDirectory;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("")
	String mainSourceFile;

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

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] platforms;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:ddoxFilterArgs")
	string[] ddoxFilterArgs;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:debugVersionFilters")
	string[] debugVersionFilters;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
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

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("x:versionFilters")
	String versionFilters;

	//@JSON!(jGetBuildTypes, buildTypesToJ)("")
	//@SDL!(sGetBuildTypes, buildTypesToS)("buildType")
	//BuildTypes buildTypes;

	@JSON!(jGetBuildOptions, buildOptionsToJ)("")
	@SDL!(sGetBuildOptions, buildOptionsToS)("")
	BuildOptions buildOptions;
}

struct BuildOptions {
	BuildOption[][immutable(Platform[])] platforms;
	BuildOption[] unspecifiedPlatform;
}

enum BuildOption {
	debugMode,  /// Compile in debug mode (enables contracts) -debug
	releaseMode,  /// Compile in release mode (disables assertions and bounds checks) -release
	coverage,  /// Enable code coverage analysis -cov
	debugInfo,  /// Enable symbolic debug information -g
	debugInfoC,  /// Enable symbolic debug information in C compatible form -gc
	alwaysStackFrame,  /// Always generate a stack frame -gs
	stackStomping,  /// Perform stack stomping -gx
	inline,  /// Perform function inlining -inline
	noBoundsCheck,  /// Disable all bounds checking -boundscheck=off
	optimize,  /// Enable optimizations -O
	profile,  /// Emit profiling code -profile
	profileGC,  /// Emit GC profiling information -profile=gc
	unittests,  /// Compile unit tests -unittest
	verbose,  /// Verbose compiler output -v
	ignoreUnknownPragmas,  /// Ignores unknown pragmas during compilation -ignore
	syntaxOnly,  /// Don't generate object files -o-
	warnings,  /// Enable warnings, enabled by default (use , buildRequirements,  to control this setting) -wi
	warningsAsErrors,  /// Treat warnings as errors (use , buildRequirements,  to control this setting) -w
	ignoreDeprecations,  /// Do not warn about using deprecated features (use , buildRequirements,  to control this setting) -d
	deprecationWarnings,  /// Warn about using deprecated features, enabled by default (use , buildRequirements,  to control this setting) -dw
	deprecationErrors,  /// Stop compilation upon usage of deprecated features (use , buildRequirements,  to control this setting) -de
	property,  /// Enforce property syntax - deprecated -property
	betterC,  /// Compile in betterC mode -betterC
}

struct SubConfigs {
	string[string][immutable(Platform[])] configs;
	string[string] unspecifiedPlatform;
}

struct BuildType {
	string name;
	string originalName;
	Platform[] platforms;
	PackageDescription pkg;
}

struct BuildTypes {
	BuildType[string] buildOptions;
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
	import std.typecons : Nullable;
	string name;
	Nullable!VersionSpecifier version_;
	UnprocessedPath path;
	Nullable!bool optional;
	Nullable!bool default_;
	Platform[] platforms;
}

struct StringPlatform {
	string str;
	Platform[] platforms;
}

struct String {
@safe pure:
	StringPlatform[] strs;
	string orig;
}

struct StringsPlatform {
	string[] strs;
	Platform[] platforms;
}

struct Strings {
	StringsPlatform[] platforms;
}
