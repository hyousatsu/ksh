/***********************************************************************
*                                                                      *
*               This software is part of the ast package               *
*          Copyright (c) 1985-2011 AT&T Intellectual Property          *
*          Copyright (c) 2020-2022 Contributors to ksh 93u+m           *
*                      and is licensed under the                       *
*                 Eclipse Public License, Version 2.0                  *
*                                                                      *
*                A copy of the License is available at                 *
*      https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.html      *
*         (with md5 checksum 84283fa8859daf213bdda5a9f8d1be1d)         *
*                                                                      *
*                 Glenn Fowler <gsf@research.att.com>                  *
*                  David Korn <dgk@research.att.com>                   *
*                   Phong Vo <kpv@research.att.com>                    *
*                                                                      *
***********************************************************************/
/*
 * Glenn Fowler
 * AT&T Bell Laboratories
 *
 * file to string vector support
 */

#include <ast.h>
#include <vecargs.h>

/*
 * free a string vector generated by vecload()
 *
 * retain!=0 frees the string pointers but retains the string data
 * in this case the data is permanently allocated
 */

void
vecfree(register char** vec, int retain)
{
	if (vec)
	{
		if (*(vec -= 2) && !retain) free(*vec);
		free(vec);
	}
}
