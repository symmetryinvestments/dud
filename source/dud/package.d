module dud;

import std.array : empty, front;
import std.algorithm.searching : countUntil;
import std.stdio;

import dud.pkgdescription;
import dud.options;

int main(string[] args) {
	const ptrdiff_t doubleSlash = args.countUntil("--");
	string[] noUserOptions = doubleSlash == -1 ? args : args[0 .. doubleSlash];

	if(noUserOptions.length == 1) {
		return 0;
	}

	switch(noUserOptions[1]) {
		case "convert":
			import dud.convert : convert;
			return convert(noUserOptions);
		default:
			writefln("Operation '%s' is not supported", noUserOptions[1]);
			return 1;
	}
}
