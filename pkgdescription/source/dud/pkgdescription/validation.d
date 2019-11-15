module dud.pkgdescription.validation;

import std.array : empty;
import std.algorithm.iteration : each, filter;
import std.exception : enforce;

import dud.pkgdescription;
import dud.pkgdescription.exception;

@safe:

void validate(ref const(PackageDescription) pkg) {
	pkg.buildTypes.validate();
}

void validate(const(BuildType[]) bts) {
	bts.each!(bt => validate(bt));
}

void validate(ref const(BuildType) bts) {
	enforce!BuildTypeException(bts.pkg.dependencies.empty,
		"A BuiltType must not have dependencies");
	enforce!BuildTypeException(bts.pkg.targetType == TargetType.autodetect,
		"TargetType must be not be set");
	enforce!BuildTypeException(bts.pkg.targetName.platforms.empty,
		"TargetName can not be changed");
	enforce!BuildTypeException(bts.pkg.targetPath.platforms.empty,
		"TargetPath can not be changed");
	enforce!BuildTypeException(bts.pkg.workingDirectory.platforms.empty,
		"WorkingDirectory can not be changed");
	enforce!BuildTypeException(bts.pkg.subConfigurations.configs.empty
			&& bts.pkg.subConfigurations.unspecifiedPlatform.empty,
		"SubConfigurations can not be changed");
}