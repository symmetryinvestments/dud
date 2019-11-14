module dud.pkgdescription.validation;

import std.algorithm.iteration : each, filter;
import std.exception : enforce;

import dud.pkgdescription;
import dud.pkgdescription.exception;

void validate(ref const(PackageDescription) pkg) {
}

void validate(const(BuildType[]) bts) {
	bts.each!(bt => validate(bt));
}

void validate(const(BuildType) bts) {
	enforce!BuildTypeException(bts.pkg.dependencies.empty,
		"A BuiltType must not have dependencies");
}
