/*
 * Copyright (C) 2009, 2016  Internet Systems Consortium, Inc. ("ISC")
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

/* $Id: backtrace-emptytbl.c,v 1.3 2009/09/01 20:13:44 each Exp $ */

/*! \file */

/*
 * This file defines an empty (default) symbol table used in backtrace.c
 * If the application wants to have a complete symbol table, it should redefine
 * isc__backtrace_symtable with the complete table in some way, and link the
 * version of the library not including this definition
 * (e.g. libisc-nosymbol.a).
 */

#include <config.h>

#include <isc/backtrace.h>

LIBISC_EXTERNAL_DATA const int isc__backtrace_nsymbols = 0;
LIBISC_EXTERNAL_DATA const
	isc_backtrace_symmap_t isc__backtrace_symtable[] = { { NULL, "" } };
