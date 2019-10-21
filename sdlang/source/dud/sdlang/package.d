// SDLang-D
// Written in the D programming language.

/++
$(H2 SDLang-D v0.9.3)

Library for parsing and generating SDL (Simple Declarative Language).

Import this module to use SDLang-D as a library.

For the list of officially supported compiler versions, see the
$(LINK2 https://github.com/Abscissa/SDLang-D/blob/master/.travis.yml, .travis.yml)
file included with your version of SDLang-D.

Links:
$(UL
	$(LI $(LINK2 https://github.com/Abscissa/SDLang-D, SDLang-D Homepage) )
	$(LI $(LINK2 http://semitwist.com/sdlang-d, SDLang-D API Reference (latest version) ) )
	$(LI $(LINK2 http://semitwist.com/sdlang-d-docs, SDLang-D API Reference (earlier versions) ) )
	$(LI $(LINK2 http://sdl.ikayzo.org/display/SDL/Language+Guide, Official SDL Site) [$(LINK2 http://semitwist.com/sdl-mirror/Language+Guide.html, mirror)] )
)

Authors: Nick Sabalausky ("Abscissa") http://semitwist.com/contact
Copyright:
Copyright (C) 2012-2015 Nick Sabalausky.

License: $(LINK2 https://github.com/Abscissa/SDLang-D/blob/master/LICENSE.txt, zlib/libpng)
+/

module dud.sdlang;

import std.array;
import std.datetime;
import std.file;
import std.stdio;

import dud.sdlang.ast;
import dud.sdlang.exception;
import dud.sdlang.lexer;
import dud.sdlang.parser;
import dud.sdlang.symbol;
import dud.sdlang.token;
import dud.sdlang.util;

// Expose main public API
public import dud.sdlang.ast : Attribute, Tag;
public import dud.sdlang.exception;
public import dud.sdlang.parser : parseFile, parseSource;
public import dud.sdlang.token : Value, Token, DateTimeFrac, DateTimeFracUnknownZone;
public import dud.sdlang.util : sdlangVersion, Location;
