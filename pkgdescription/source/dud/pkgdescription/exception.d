module dud.pkgdescription.exception;

import std.array : empty;
import std.typecons : nullable, Nullable;
import std.format : format;

import dud.exception;

@safe pure:

struct Location {
@safe:
	const string filename;
	const size_t line;
	const size_t column;

	string toString() const {
		return this.filename.empty
			? format("Line:%s Column:%s", this.line,
				this.column)
			: format("File:%s Line:%s Column:%s", this.filename, this.line,
				this.column);
	}
}

string exceptionClassBuilder(string name, string superName) {
	import std.format : format;

	return q{
class %1$s : %2$s {
	Nullable!Location location;
	this(string msg, string file = __FILE__, size_t line = __LINE__)
		@safe pure nothrow @nogc
	{
		super(msg, file, line);
	}

	this(string msg, string file = __FILE__, size_t line = __LINE__,
			Throwable next = null) @safe pure nothrow @nogc
	{
		super(msg, file, line, next);
	}

	this(string msg, Location loc, string file = __FILE__,
			size_t line = __LINE__) @safe pure nothrow @nogc
	{
		super(msg, file, line);
		this.location = nullable(loc);
	}

	override string toString() {
		return format("%1$s: %%s %%s", this.msg,
			(this.location.isNull() ? "" : this.location.toString()));
	}
}
}.format(name, superName);
}

mixin(exceptionClassBuilder("DudPkgDescriptionException", "DudException"));
mixin(exceptionClassBuilder("KeyNotHandled", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("WrongType", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("WrongTypeJSON", "WrongType"));
mixin(exceptionClassBuilder("WrongTypeSDL", "WrongType"));
mixin(exceptionClassBuilder("SingleElement", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("NoValues", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("EmptyInput", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("UnexpectedInput", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("ConflictingInput", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("ConflictingOutput", "DudPkgDescriptionException"));
mixin(exceptionClassBuilder("UnsupportedAttributes", "DudPkgDescriptionException"));
