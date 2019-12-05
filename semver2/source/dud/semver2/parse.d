module dud.semver2.parse;

import dud.semver2.semver;

import std.array : array, back, empty, front, popFront;
import std.algorithm.searching : all, countUntil;
import std.algorithm.iteration : map, splitter;
import std.conv : to;
import std.format : format;
import std.exception : enforce;
import std.ascii : isDigit;
import std.utf : byChar, byUTF;

@safe:

SemVer parseSemVer(string input) {
	SemVer ret;

	char[] inputRange = to!(char[])(input);

	ret.major = splitOutNumber!isDot("Major", "first", inputRange);
	ret.minor = splitOutNumber!isDot("Minor", "second", inputRange);
	ret.patch = toNum("Patch", dropUntilPredOrEmpty!isPlusOrMinus(inputRange));
	if(!inputRange.empty && inputRange[0].isMinus()) {
		inputRange.popFront();
		ret.preRelease = splitter(dropUntilPredOrEmpty!isPlus(inputRange), '.')
			.map!(it => checkASCII(it))
			.map!(it => to!string(it))
			.array;
	}
	if(!inputRange.empty) {
		enforce(inputRange[0] == '+',
			format("Expected a '+' got '%s'", inputRange[0]));
		inputRange.popFront();
		ret.buildIdentifier =
			splitter(dropUntilPredOrEmpty!isFalse(inputRange), '.')
			.map!(it => checkASCII(it))
			.map!(it => to!string(it))
			.array;
	}
	enforce(inputRange.empty,
		format("Surprisingly input '%s' left", inputRange));
	return ret;
}

char[] checkASCII(char[] cs) {
	import std.ascii : isAlpha;
	foreach(it; cs.byUTF!char()) {
		enforce(isDigit(it) || isAlpha(it) || it == '-', format(
			"Non ASCII character '%s' surprisingly found input '%s'",
			it, cs
		));
	}
	return cs;
}

uint toNum(string numName, char[] input) {
	enforce(all!isDigit(input),
		format("%s range must solely consist of digits not '%s'",
			numName, input));
	return to!uint(input);
}

uint splitOutNumber(alias pred)(const string numName, const string dotName,
		ref char[] input)
{
	const ptrdiff_t dot = input.byUTF!char().countUntil!pred();
	enforce(dot != -1,
		format("Couldn't find the %s dot in '%s'", dotName, input));
	char[] num = input[0 .. dot];
	const uint ret = toNum(numName, num);
	enforce(input.length > dot + 1,
		format("Input '%s' ended surprisingly after %s version",
			input, numName));
	input = input[dot + 1 .. $];
	return ret;
}

char[] dropUntilPredOrEmpty(alias pred)(ref char[] input) {
	size_t pos;
	while(pos < input.length && !pred(input[pos])) {
		++pos;
	}
	char[] ret = input[0 .. pos];
	input = input[pos .. $];
	return ret;
}

bool isFalse(char c) {
	return false;
}

bool isDot(char c) {
	return c == '.';
}

bool isMinus(char c) {
	return c == '-';
}

bool isPlus(char c) {
	return c == '+';
}

bool isPlusOrMinus(char c) {
	return isPlus(c) || isMinus(c);
}
