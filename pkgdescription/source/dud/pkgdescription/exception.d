module dud.pkgdescription.exception;

import std.typecons : Nullable;

import dud.exception;

mixin(exceptionClassBuilder("DudPkgDescriptionException", "DudException"));

struct Location {
	const string filename;
	const size_t line;
	const size_t column;
}

class KeyNotHandled : DudPkgDescriptionException {
	Nullable!Location location;

	this(string msg, string file = __FILE__, size_t line = __LINE__)
		@safe pure nothrow @nogc
	{
		super(msg, file, line);
	}
}

mixin(exceptionClassBuilder("WrongType", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("WrongTypeJSON", "WrongType"));

class WrongTypeSDL : WrongType {
	Location location;

	this(string msg, Location loc, string file = __FILE__,
			size_t line = __LINE__) @safe pure nothrow @nogc
	{
		super(msg, file, line);
		this.location = loc;
	}
}
