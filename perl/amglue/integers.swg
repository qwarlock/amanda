/*
 * Copyright (c) 2007-2012 Zmanda, Inc.  All Rights Reserved.
 * Copyright (c) 2013-2016 Carbonite, Inc.  All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 * Contact information: Carbonite Inc., 756 N Pastoria Ave
 * Sunnyvale, CA 94085, or: http://www.zmanda.com
 */

%{
#include "amglue.h"
%}

/*
 * perl -> C (input)
 */

%typemap(in) guint64 {
    gchar *err = NULL;
    $1 = amglue_SvU64($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) gint64 {
    gchar *err = NULL;
    $1 = amglue_SvI64($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) guint32 {
    gchar *err = NULL;
    $1 = amglue_SvU32($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) uint32_t {
    gchar *err = NULL;
    $1 = amglue_SvU32($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) gint32 {
    gchar *err = NULL;
    $1 = amglue_SvI32($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) guint16 {
    gchar *err = NULL;
    $1 = amglue_SvU16($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) gint16 {
    gchar *err = NULL;
    $1 = amglue_SvI16($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) guint8 {
    gchar *err = NULL;
    $1 = amglue_SvU8($input, &err);
    if (err) croak("%s", err);
}

%typemap(in) gint8 {
    gchar *err = NULL;
    $1 = amglue_SvI8($input, &err);
    if (err) croak("%s", err);
}

%typedef unsigned pid_t;

/* remaining types depend on the complier to optimize out constant sizeof() 
 * expressions.  The SWIG preprocessor can't perform calculations based on 
 * sizeof(). */

%define typemap_in_unsigned(type)
%typemap(in) type {
    gchar *err = NULL;
    if (sizeof(type) == 1) {
	$1 = amglue_SvU8($input, &err);
    } else if (sizeof(type) == 2) {
	$1 = amglue_SvU16($input, &err);
    } else if (sizeof(type) == 4) {
	$1 = amglue_SvU32($input, &err);
    } else if (sizeof(type) == 8) {
	$1 = amglue_SvU64($input, &err);
    } else {
	croak("Unexpected type >64 bits?"); /* should be optimized out unless sizeof(type) > 8 */
    }
    if (err) croak("%s", err);
}
%enddef

typemap_in_unsigned(unsigned int)
typemap_in_unsigned(guint)
typemap_in_unsigned(unsigned short)
typemap_in_unsigned(gushort)
typemap_in_unsigned(size_t)
typemap_in_unsigned(gsize)
typemap_in_unsigned(unsigned long long)
typemap_in_unsigned(unsigned long)
typemap_in_unsigned(gulong)
typemap_in_unsigned(off_t)
typemap_in_unsigned(ptrdiff_t)
typemap_in_unsigned(uintmax_t)

%define typemap_in_signed(type)
%typemap(in) type {
    gchar *err = NULL;
    if (sizeof(type) == 1) {
	$1 = amglue_SvI8($input, &err);
    } else if (sizeof(type) == 2) {
	$1 = amglue_SvI16($input, &err);
    } else if (sizeof(type) == 4) {
	$1 = amglue_SvI32($input, &err);
    } else if (sizeof(type) == 8) {
	$1 = amglue_SvI64($input, &err);
    } else {
	g_critical("Unexpected type >64 bits?"); /* should be optimized out unless sizeof(type) > 8 */
    }
    if (err) croak("%s", err);
}
%enddef

typemap_in_signed(int)
typemap_in_signed(gint)
typemap_in_signed(signed int)
typemap_in_signed(short)
typemap_in_signed(gshort)
typemap_in_signed(signed short)
typemap_in_signed(ssize_t)
typemap_in_signed(gssize)
typemap_in_signed(long long)
typemap_in_signed(signed long long)
typemap_in_signed(long)
typemap_in_signed(signed long)
typemap_in_signed(glong)
typemap_in_signed(intmax_t)

/*
 * C -> perl (output)
 */

/* All conversions from C to Perl create Math::BigInt objects, even when the
 * C datatype is 32 bits or smaller.  This is to ensure that Perl's automatic
 * promotion to double does not silently corrupt arithmetic on large numbers.
 *
 * The complex typemaps here are to ensure that the argument stack is protected
 * against stomping by amglue_newSV*64, which may invoke a significant amount
 * of perl code.  "SP += argvi; PUTBACK;" increments the global stack pointer
 * to cover the arguments processed so far, while "SPAGAIN; SP -= argvi;"
 * restores the local stack pointer.  The latter must be done before the newest
 * argument is added to the stack.  This whole process is a hack around SWIG's
 * habit of invoking (out) typemaps while building the stack, instead of doing
 * so in advance.
 */

/* (these all use newSV*64, relying on C to upcast to a 64-bit integer) */

%define typemap_out_unsigned(type)
%typemap(out) type {
    SV *for_stack;
    SP += argvi; PUTBACK;
    for_stack = sv_2mortal(amglue_newSVu64($1));
    SPAGAIN; SP -= argvi;
    $result = for_stack;
    argvi++;
}
%enddef

typemap_out_unsigned(guint64)
typemap_out_unsigned(guint32)
typemap_out_unsigned(uint32_t)
typemap_out_unsigned(guint16)
typemap_out_unsigned(guint8)
typemap_out_unsigned(unsigned int)
typemap_out_unsigned(guint)
typemap_out_unsigned(unsigned short)
typemap_out_unsigned(gushort)
typemap_out_unsigned(size_t)
typemap_out_unsigned(gsize)
typemap_out_unsigned(unsigned long long)
typemap_out_unsigned(unsigned long)
typemap_out_unsigned(gulong)
typemap_out_unsigned(off_t)
typemap_out_unsigned(ptrdiff_t)
typemap_out_unsigned(uintmax_t)

%define typemap_out_signed(type)
%typemap(out) type {
    SV *for_stack;
    SP += argvi; PUTBACK;
    for_stack = sv_2mortal(amglue_newSVi64($1));
    SPAGAIN; SP -= argvi;
    $result = for_stack;
    argvi++;
}
%enddef

typemap_out_signed(gint64)
typemap_out_signed(gint32)
typemap_out_signed(gint16)
typemap_out_signed(gint8)
typemap_out_signed(int)
typemap_out_signed(gint)
typemap_out_signed(signed int)
typemap_out_signed(short)
typemap_out_signed(gshort)
typemap_out_signed(signed short)
typemap_out_signed(ssize_t)
typemap_out_signed(gssize)
typemap_out_signed(long long)
typemap_out_signed(signed long long)
typemap_out_signed(long)
typemap_out_signed(signed long)
typemap_out_signed(glong)
typemap_out_signed(intmax_t)
