module dud.resolve.providiertest;

import std.stdio;

import dud.resolve.providier;

unittest {
	auto dfp = fromDumpFile("../testdata/dump_short.json");

	//auto graphqld = dfp.getPackages("graphqld", "^1.0.0");
	//writeln(graphqld);
}
