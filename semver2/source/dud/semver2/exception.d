module dud.semver2.exception;

import std.exception : basicExceptionCtors;
import dud.exception;

class SemVerParseException : DudException {
	mixin basicExceptionCtors;
}

class NonAsciiChar : SemVerParseException {
	mixin basicExceptionCtors;
}

class EmptyInput : SemVerParseException {
	mixin basicExceptionCtors;
}

class OnlyDigitAllowed : SemVerParseException {
	mixin basicExceptionCtors;
}

class InvalidSeperator : SemVerParseException {
	mixin basicExceptionCtors;
}

class InputNotEmpty : SemVerParseException {
	mixin basicExceptionCtors;
}
