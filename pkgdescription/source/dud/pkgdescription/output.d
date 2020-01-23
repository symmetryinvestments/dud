module dud.pkgdescription.output;

import std.algorithm.iteration : filter, map;
import std.array : appender, array, back, empty, front;
import std.conv : to;
import std.exception : enforce;
import std.format : format, formattedWrite;
import std.json;
import std.typecons : Nullable;
import std.stdio;

import dud.pkgdescription;
import dud.pkgdescription.json;
import dud.pkgdescription.sdl;

@safe:

JSONValue toJSON(const PackageDescription pkg) pure {
	return packageDescriptionToJ(pkg);
}

string toSDL(const PackageDescription pkg) {
	auto app = appender!string();
	toSDL(pkg, app);
	return app.data;
}

void toSDL(Out)(const PackageDescription pkg, auto ref Out o) {
	packageDescriptionToS(o, pkg.name, pkg, 0);
}
