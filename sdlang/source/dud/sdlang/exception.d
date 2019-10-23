// SDLang-D
// Written in the D programming language.

module dud.sdlang.exception;

import std.exception;
import std.string;

import dud.sdlang.util;

@safe pure:

abstract class SDLangException : Exception
{
	this(string msg) pure @safe { super(msg); }
}

class SDLangParseException : SDLangException
{
	Location location;
	bool hasLocation;

	this(string msg) pure @safe {
		hasLocation = false;
		super(msg);
	}

	this(Location location, string msg) pure @safe {
		hasLocation = true;
		super("%s: %s".format(location.toString(), msg));
	}
}

class SDLangValidationException : SDLangException
{
	this(string msg) pure @safe { super(msg); }
}

class SDLangRangeException : SDLangException
{
	this(string msg) pure @safe { super(msg); }
}
