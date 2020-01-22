module dud.pkgdescription.convtest;

import std.stdio;
import std.array : empty, front;
import std.algorithm.iteration : filter, map;
import std.algorithm.searching : endsWith;
import std.file : readText;
import std.format : format;
import std.exception : ifThrown;
import std.range : chain;
import std.typecons : tuple;
import std.json;

import dud.testdata;
import dud.pkgdescription;
import dud.pkgdescription.sdl;
import dud.pkgdescription.json;
import dud.pkgdescription.output;
import dud.pkgdescription.testhelper;
import dud.pkgdescription.exception;
import dud.pkgdescription.helper;

@safe:

void fun1() {
	string input = q{
configuration "windows-release" {
  preBuildCommands "cd $PACKAGE_DIR\\cpp && cmake . -G \"Visual Studio 14 2015 Win64\" && cmake --build . --config Release" platform="windows-x86_64"
  preBuildCommands "cd $PACKAGE_DIR\\cpp && cmake . -G \"Visual Studio 14 2015\" && cmake --build . --config Release" platform="windows-x86_mscoff"
}
};
	PackageDescription a = sdlToPackageDescription(input);
	assert(a.configurations["windows-release"]
			.preBuildCommands.platforms[0].platforms
			== [ Platform.windows, Platform.x86_64],
		format("%s", a.configurations["windows-release"].preBuildCommands));
	assert(a.configurations["windows-release"]
			.preBuildCommands.platforms[1].platforms
			== [ Platform.windows, Platform.x86_mscoff],
		format("%s", a.configurations["windows-release"].preBuildCommands));
	JSONValue j = a.toJSON();
	PackageDescription b = jsonToPackageDescription(j);

	assert(a == b,
		j.toPrettyString());
		//pkgCompare(a, b));
}

version(ExcessivConvTests):

void fun2() {
	auto all = chain(
		() @trusted { return allDubJSONFiles(); }(),
		() @trusted { return allDubSDLFiles(); }())
		.map!(fn => tuple(fn, readText(fn)))
		.map!(t => tuple(t[0],
			t[0].endsWith(".sdl")
				? sdlToPackageDescription(t[1])
					.ifThrown(PackageDescription.init)
				: jsonToPackageDescription(t[1])
					.ifThrown(PackageDescription.init)))
		.filter!(t => t[1] != PackageDescription.init);

	size_t idx;
	size_t failed;
	size_t worked;
	size_t[TestFailKind] failCnt;
	foreach(it; all) {
		//writefln("%s %s", idx, it[0]);
		try {
			PackageDescription a = it[1];
			JSONValue js = testToJson(a, it[0], failCnt);
			if(js == JSONValue.init) {
				incrementFailCnt(failCnt, TestFailKind.toJson);
				continue;
			}
			PackageDescription b = jsonToPackageDescription(js);
			if(b != a) {
				writefln("%5d %s\nb == a failed\n%s", idx, it[0],
						pkgCompare(b, a));
				incrementFailCnt(failCnt, TestFailKind.fromJsonCopy);
				continue;
			}


			string sdlOut = testToSDL(a, it[0], failCnt);
			//writefln("%s:\n%s", it[0], sdlOut);
			PackageDescription c;
			try {
				c = sdlToPackageDescription(sdlOut);
				assert(a == c,
					() @trusted {
						return format("f: %s\nexp:\n%s\ngot:\n%s", it[0], a, c);
					}());
			} catch(Exception e) {
				unRollException(e, it[0]);
				incrementFailCnt(failCnt, TestFailKind.fromSDLCopy);
				continue;
			}

			PackageDescription copy = ddupTest(a, it[0], failCnt);

			if(b != c) {
				writefln("%5d %s\nb == c failed\n%s", idx, it[0],
						pkgCompare(b, c));
				incrementFailCnt(failCnt, TestFailKind.cmp);
				continue;
			}

			++worked;
		} catch(Exception e) {
			//unRollException(e, it[0]);
		}

		++idx;
	}
	writefln("fails %s, %d worked", failCnt, worked);
}

void main() {
	fun1();
	fun2();
}
