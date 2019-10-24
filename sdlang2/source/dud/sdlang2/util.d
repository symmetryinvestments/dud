module dud.sdlang2.util;

import std.traits : isFloatingPoint, isFunctionPointer, isDelegate,
	   functionAttributes, FunctionAttribute, SetFunctionAttributes,
	   functionLinkage;

string floatToStringPure(T)(T t) @safe pure if(isFloatingPoint!T) {
	static if(is(T == float)) {
		auto dl = assumePure(&floatToStringPureFloat);
	} else static if(is(T == double)) {
		auto dl = assumePure(&floatToStringPureDouble);
	} else static if(is(T == real)) {
		auto dl = assumePure(&floatToStringPureReal);
	}
	return dl(t);
}

auto assumePure(T)(T t) @trusted
if (isFunctionPointer!T || isDelegate!T)
{
    enum attrs = functionAttributes!T | FunctionAttribute.pure_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

private string floatToStringPureFloat(float t) @safe {
	import std.format : format;
	return format("%s", t);
}

private string floatToStringPureDouble(double t) @safe {
	import std.format : format;
	return format("%s", t);
}

private string floatToStringPureReal(real t) @safe {
	import std.format : format;
	return format("%s", t);
}
