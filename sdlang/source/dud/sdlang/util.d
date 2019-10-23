// SDLang-D
// Written in the D programming language.

module dud.sdlang.util;

import std.algorithm;
import std.datetime;
import std.stdio;
import std.string;

import dud.sdlang.token;

@safe:

enum sdlangVersion = "0.9.1";

alias immutable(ubyte)[] ByteString;

auto startsWith(T)(string haystack, T needle) pure
	if( is(T:ByteString) || is(T:string) )
{
	return std.algorithm.startsWith( cast(ByteString)haystack, cast(ByteString)needle );
}

struct Location
{
	pure:
	string file; /// Filename (including path)
	int line; /// Zero-indexed
	int col;  /// Zero-indexed, Tab counts as 1
	size_t index; /// Index into the source

	this(int line, int col, int index)
	{
		this.line  = line;
		this.col   = col;
		this.index = index;
	}

	this(string file, int line, int col, int index)
	{
		this.file  = file;
		this.line  = line;
		this.col   = col;
		this.index = index;
	}

	string toString()
	{
		return "%s(%s:%s)".format(file, line+1, col+1);
	}
}

void removeIndex(E)(ref E[] arr, ptrdiff_t index) pure
{
	arr = arr[0..index] ~ arr[index+1..$];
}

void trace(string file=__FILE__, size_t line=__LINE__, TArgs...)(TArgs args)
	pure
{
	version(sdlangTrace)
	{
		writeln(file, "(", line, "): ", args);
		stdout.flush();
	}
}

// very dirty hack because object.opEquals is not pure
import std.traits : isFunctionPointer, isDelegate, functionAttributes,
	   FunctionAttribute, SetFunctionAttributes, functionLinkage;

auto assumePure(T)(T t) @trusted
if (isFunctionPointer!T || isDelegate!T)
{
    enum attrs = functionAttributes!T | FunctionAttribute.pure_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

string toString(TypeInfo ti) @safe pure {
	auto dl = assumePure(&toStringImpl);
	return dl(ti);
}

string toStringImpl(TypeInfo ti) @trusted
{
	if     (ti == typeid( bool         )) return "bool";
	else if(ti == typeid( string       )) return "string";
	else if(ti == typeid( dchar        )) return "dchar";
	else if(ti == typeid( int          )) return "int";
	else if(ti == typeid( long         )) return "long";
	else if(ti == typeid( float        )) return "float";
	else if(ti == typeid( double       )) return "double";
	else if(ti == typeid( real         )) return "real";
	else if(ti == typeid( Date         )) return "Date";
	else if(ti == typeid( DateTimeFrac )) return "DateTimeFrac";
	else if(ti == typeid( DateTimeFracUnknownZone )) return "DateTimeFracUnknownZone";
	else if(ti == typeid( SysTime      )) return "SysTime";
	else if(ti == typeid( Duration     )) return "Duration";
	else if(ti == typeid( ubyte[]      )) return "ubyte[]";
	else if(ti == typeid( typeof(null) )) return "null";

	return "{unknown}";
}

enum BOM {
	UTF8,           /// UTF-8
	UTF16LE,        /// UTF-16 (little-endian)
	UTF16BE,        /// UTF-16 (big-endian)
	UTF32LE,        /// UTF-32 (little-endian)
	UTF32BE,        /// UTF-32 (big-endian)
}

enum NBOM = __traits(allMembers, BOM).length;
immutable ubyte[][NBOM] ByteOrderMarks =
[
	[0xEF, 0xBB, 0xBF],         //UTF8
	[0xFF, 0xFE],               //UTF16LE
	[0xFE, 0xFF],               //UTF16BE
	[0xFF, 0xFE, 0x00, 0x00],   //UTF32LE
	[0x00, 0x00, 0xFE, 0xFF]    //UTF32BE
];

void strAssert(string a, string b) {
	import std.format : format;
	assert(a == b, format("\nexp: %s\ngot: %s", b, a));
}
