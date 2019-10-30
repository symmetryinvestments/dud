module dud.pkgdescription;

import std.typecons : Nullable;

import dud.path;
import dud.semver;
import dud.pkgdescription.versionspecifier;
import dud.pkgdescription.udas;
import dud.pkgdescription.json;
import dud.pkgdescription.sdl;

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
	@SDL!(sGetString, stringToS)("")
	string name; /// Qualified name of the package

	@JSON!(jGetSemVer, semVerToJ)("version")
	@SDL!(sGetSemVer, semVerToS)("")
	Nullable!SemVer version_; /// Version of the package

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
	@JSON!(sGetDependencies, dependenciesToS)("dependency")
	Dependency[string] dependencies;

	@JSON!(jGetTargetType, targetTypeToJ)("")
	TargetType targetType;

	@JSON!(jGetPath, pathToJ)("")
	Path targetPath;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string targetName;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string targetFileName;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string workingDirectory;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string mainSourceFile;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] dflags; /// Flags passed to the D compiler

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] lflags; /// Flags passed to the linker

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] libs; /// Librariy names to link against (typically using "-l<name>")

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] copyFiles; /// Files to copy to the target directory

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] extraDependencyFiles; /// Files to check for rebuild dub project

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] versions; /// D version identifiers to set

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] debugVersions; /// D debug version identifiers to set

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] importPaths;

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] sourcePaths;

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] sourceFiles;

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] excludedSourceFiles;

	@JSON!(jGetPaths, pathsToJ)("")
	Path[] stringImportPaths;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] preGenerateCommands; /// commands executed before creating the description

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] postGenerateCommands; /// commands executed after creating the description

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] preBuildCommands; /// Commands to execute prior to every build

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] postBuildCommands; /// Commands to execute after every build

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] preRunCommands; /// Commands to execute prior to every run

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] postRunCommands; /// Commands to execute after every run

	@JSON!(jGetPackageDescriptions, packageDescriptionsToJ)("")
	PackageDescription[] configurations;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] platforms;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:ddoxFilterArgs")
	string[] ddoxFilterArgs;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("x:ddoxTool")
	string ddoxTool;

	//@SDLName("subPackage")
	@JSON!(jGetSubPackages, subPackagesToJ)("")
	SubPackage[] subPackages;

	@JSON!(jGetBuildRequirements, buildRequirementsToJ)("")
	BuildRequirements[] buildRequirements;

	//@SDLName("subConfiguration")
	@JSON!(jGetStringAA, stringAAToJ)("")
	string[string] subConfigurations;

	@JSON!(jGetString, stringToJ)()
	@SDL!(sGetString, stringToS)("x:versionFilters")
	string versionFilters;
}

enum BuildRequirements {
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
	Nullable!Path path;
	Nullable!PackageDescription inlinePkg;
}

struct Dependency {
	import std.typecons : Nullable;
	string name;
	Nullable!VersionSpecifier version_;
	Nullable!Path path;
	Nullable!bool optional;
	Nullable!bool default_;
}
