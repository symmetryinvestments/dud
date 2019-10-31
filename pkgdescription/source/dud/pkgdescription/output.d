module dud.pkgdescription.output;

import std.algorithm.iteration : filter, map;
import std.array : appender, array, back, empty, front;
import std.conv : to;
import std.exception : enforce;
import std.format : format, formattedWrite;
import std.json;
import std.typecons : Nullable;
import std.stdio;

import dud.semver;
import dud.pkgdescription;
import dud.pkgdescription.versionspecifier;
import dud.pkgdescription.helper;
import dud.pkgdescription.udas;
import dud.pkgdescription.json;
import dud.pkgdescription.sdl;

@safe pure:

JSONValue toJSON(PackageDescription pkg) {
	return packageDescriptionToJ(pkg);
}

string toSDL(PackageDescription pkg) {
	auto app = appender!string();
	toSDL(pkg, app);
	return app.data;
}

void toSDL(Out)(PackageDescription pkg, auto ref Out o) {
	packageDescriptionToS(o, pkg.name, pkg, 0);
}
