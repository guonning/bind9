/*
 * Copyright (C) 1998-2001, 2004-2007, 2016  Internet Systems Consortium, Inc. ("ISC")
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

/* $Id: boolean.h,v 1.19 2007/06/19 23:47:18 tbox Exp $ */

#ifndef ISC_BOOLEAN_H
#define ISC_BOOLEAN_H 1

/*! \file isc/boolean.h */

typedef enum { isc_boolean_false = 0, isc_boolean_true = 1 } isc_boolean_t;

#define ISC_FALSE isc_boolean_false
#define ISC_TRUE isc_boolean_true
#define ISC_TF(x) ((x) ? ISC_TRUE : ISC_FALSE)

#endif /* ISC_BOOLEAN_H */
