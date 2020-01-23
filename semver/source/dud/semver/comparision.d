module dud.semver.comparision;

import std.array : empty;
import std.typecons : nullable, Nullable;

import dud.semver.semver;
import dud.semver.exception;

@safe pure:

int compare(const(SemVer) a, const(SemVer) b) nothrow {
	if(a.major != b.major) {
		return a.major < b.major ? -1 : 1;
	}

	if(a.minor != b.minor) {
		return a.minor < b.minor ? -1 : 1;
	}

	if(a.patch != b.patch) {
		return a.patch < b.patch ? -1 : 1;
	}

	if(a.preRelease.empty != b.preRelease.empty) {
		return a.preRelease.empty ? 1 : -1;
	}

	size_t idx;
	while(idx < a.preRelease.length && idx < b.preRelease.length) {
		string aStr = a.preRelease[idx];
		string bStr = b.preRelease[idx];
		Nullable!uint aNumN = isAllNum(aStr);
		Nullable!uint bNumN = isAllNum(bStr);
		if(!aNumN.isNull() && !bNumN.isNull()) {
			uint aNum = aNumN.get();
			uint bNum = bNumN.get();

			if(aNum != bNum) {
				return aNum < bNum ? -1 : 1;
			}
		} else if(aStr != bStr) {
			return aStr < bStr ? -1 : 1;
		}
		++idx;
	}

	if(idx == a.preRelease.length && idx == b.preRelease.length) {
		return 0;
	}

	return idx < a.preRelease.length ? 1 : -1;
}

Nullable!uint isAllNum(string s) nothrow {
	import std.utf : byUTF;
	import dud.semver.helper : isDigit;
	import std.algorithm.searching : all;
	import std.conv : to, ConvException;

	const bool allNum = s.byUTF!char().all!isDigit();

	if(allNum) {
		try {
			return nullable(to!uint(s));
		} catch(Exception e) {
			assert(false, s);
		}
	}
	return Nullable!(uint).init;
}

unittest {
	import std.format : format;
	auto i = isAllNum("hello world");
	assert(i.isNull());

	i = isAllNum("12354");
	assert(!i.isNull());
	assert(i.get() == 12354);

	i = isAllNum("0002354");
	assert(!i.isNull());
	assert(i.get() == 2354);
}
