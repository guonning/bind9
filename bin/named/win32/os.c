/*
 * Copyright (C) 1999-2001  Internet Software Consortium.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM
 * DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL
 * INTERNET SOFTWARE CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
 * FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
 * WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/* $Id: os.c,v 1.4 2001/08/09 02:55:38 mayer Exp $ */

#include <config.h>
#include <stdarg.h>

#include <sys/stat.h>

#include <ctype.h>
#include <errno.h>
#include <io.h>
#include <process.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

#include <isc/print.h>
#include <isc/result.h>
#include <isc/string.h>
#include <isc/ntpaths.h>

#include <named/main.h>
#include <named/os.h>
#include <named/globals.h>
#include <named/ntservice.h>


static char *pidfile = NULL;

static BOOL Initialized = FALSE;

void
ns_paths_init() {
	if (!Initialized)
		isc_ntpaths_init();

	ns_g_conffile = isc_ntpaths_get(NAMED_CONF_PATH);
	lwresd_g_conffile = isc_ntpaths_get(LWRES_CONF_PATH);
	lwresd_g_resolvconffile = isc_ntpaths_get(RESOLV_CONF_PATH);
	ns_g_conffile = isc_ntpaths_get(NAMED_CONF_PATH);
	ns_g_defaultpidfile = isc_ntpaths_get(NAMED_PID_PATH);
	lwresd_g_defaultpidfile = isc_ntpaths_get(LWRESD_PID_PATH);
	ns_g_autorndckeyfile = isc_ntpaths_get(RNDC_KEY_PATH);

	Initialized = TRUE;
}


static void
setup_syslog(const char *progname) {
	int options;

	options = LOG_PID;
#ifdef LOG_NDELAY
	options |= LOG_NDELAY;
#endif

	openlog(progname, options, LOG_DAEMON);
}

void
ns_os_init(const char *progname) {
	ns_paths_init();
	setup_syslog(progname);
	ntservice_init();
}

void
ns_os_daemonize(void) {
	int fd;

	/*
	 * Try to set stdin, stdout, and stderr to /dev/null, but press
	 * on even if it fails.
	 *
	 * XXXMLG The close() calls here are unneeded on all but NetBSD, but
	 * are harmless to include everywhere.  dup2() is supposed to close
	 * the FD if it is in use, but unproven-pthreads-0.16 is broken
	 * and will end up closing the wrong FD.  This will be fixed eventually,
	 * and these calls will be removed.
	 */
	fd = open("NUL", O_RDWR, 0);
	if (fd != -1) {
		close(_fileno(stdin));
		(void)_dup2(fd, _fileno(stdin));
		close(_fileno(stdout));
		(void)_dup2(fd, _fileno(stdout));
		close(_fileno(stderr));
		(void)_dup2(fd, _fileno(stderr));
		if (fd != _fileno(stdin) &&
		    fd != _fileno(stdout) &&
		    fd != _fileno(stderr))
			(void)close(fd);
	}
}

void
ns_os_chroot(const char *root) {
}

void
ns_os_inituserinfo(const char *username) {
}

void
ns_os_changeuser(void) {
}

void
ns_os_minprivs(void) {
}

static int
safe_open(const char *filename, isc_boolean_t append) {
	int fd;
        struct stat sb;

        if (stat(filename, &sb) == -1) {
                if (errno != ENOENT)
			return (-1);
        } else if ((sb.st_mode & S_IFREG) == 0)
		return (-1);

	if (append)
		fd = open(filename, O_WRONLY|O_CREAT|O_APPEND,
		     S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
	else {
		(void)unlink(filename);
		fd = open(filename, O_WRONLY|O_CREAT|O_EXCL,
		     S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
	}
	return (fd);
}

static void
cleanup_pidfile(void) {
	if (pidfile != NULL) {
		(void)unlink(pidfile);
		free(pidfile);
	}
	pidfile = NULL;
}

void
ns_os_writepidfile(const char *filename) {
        int fd;
	FILE *lockfile;
	size_t len;
	pid_t pid;

	/*
	 * The caller must ensure any required synchronization.
	 */

	cleanup_pidfile();

	len = strlen(filename);
	pidfile = malloc(len + 1);
	if (pidfile == NULL)
                ns_main_earlyfatal("couldn't malloc '%s': %s",
				   filename, strerror(errno));
	/* This is safe. */
	strcpy(pidfile, filename);

        fd = safe_open(filename, ISC_FALSE);
        if (fd < 0)
                ns_main_earlyfatal("couldn't open pid file '%s': %s",
				   filename, strerror(errno));
        lockfile = fdopen(fd, "w");
        if (lockfile == NULL)
		ns_main_earlyfatal("could not fdopen() pid file '%s': %s",
				   filename, strerror(errno));

		pid = getpid();
        if (fprintf(lockfile, "%ld\n", (long)pid) < 0)
                ns_main_earlyfatal("fprintf() to pid file '%s' failed",
				   filename);
        if (fflush(lockfile) == EOF)
                ns_main_earlyfatal("fflush() to pid file '%s' failed",
				   filename);
	(void)fclose(lockfile);
}

void
ns_os_shutdown(void) {
	closelog();
	cleanup_pidfile();
	ntservice_shutdown();	/* This MUST be the last thing done */
}