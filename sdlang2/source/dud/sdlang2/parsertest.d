module dud.sdlang2.parsertest;

import std.range : walkLength;

import dud.sdlang2.lexer;
import dud.sdlang2.parser;
import dud.sdlang2.ast;
import dud.sdlang2.astaccess;
import dud.sdlang2.value;

@safe pure:
unittest {
	auto l = Lexer(`key "value"`);
	auto p = Parser(l);
	Root r = p.parseRoot();

	foreach(tag; tags(r)) {
		assert(tag.identifer() == "key", tag.identifer());
		auto vals = tag.values();
		assert(!vals.empty);
		assert(vals.front.type == ValueType.str);
	}
}
