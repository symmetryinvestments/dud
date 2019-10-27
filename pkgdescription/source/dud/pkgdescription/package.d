module dud.pkgdescription;

import dud.path;
import dud.semver;
import dud.pkgdescription.versionspecifier;

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
	Path path; /// Path to the package
	string name; /// Qualified name of the package
	SemVer version_; /// Version of the package
	string description;
	string homepage;
	string[] authors;
	string copyright;
	string license;
	Dependency[string] dependencies;

	TargetType targetType;
	Path targetPath;
	string targetName;
	string targetFileName;
	string workingDirectory;
	string mainSourceFile;
	string[] dflags; /// Flags passed to the D compiler
	string[] lflags; /// Flags passed to the linker
	string[] libs; /// Librariy names to link against (typically using "-l<name>")
	string[] copyFiles; /// Files to copy to the target directory
	string[] extraDependencyFiles; /// Files to check for rebuild dub project
	string[] versions; /// D version identifiers to set
	string[] debugVersions; /// D debug version identifiers to set
	Path[] importPaths;
	Path[] stringImportPaths;
	string[] preGenerateCommands; /// commands executed before creating the description
	string[] postGenerateCommands; /// commands executed after creating the description
	string[] preBuildCommands; /// Commands to execute prior to every build
	string[] postBuildCommands; /// Commands to execute after every build
	string[] preRunCommands; /// Commands to execute prior to every run
	string[] postRunCommands; /// Commands to execute after every run
	PackageDescription[] configurations;
}

struct Dependency {
	import std.typecons : Nullable;
	string name;
	Nullable!VersionSpecifier version_;
	Nullable!Path path;
	Nullable!bool optional;
	Nullable!bool default_;
}
