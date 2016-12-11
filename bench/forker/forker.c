#include <sys/types.h>
#include <sys/wait.h>

#include <err.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#define	NFORKS	100000

static void
usage(void)
{

	fprintf(stderr,
"usage: forker [-n <nforks>] [-c <count>] [-C] [-r]\n\n"
"    -n <nforks>  -- Number of forks to perform, default %d\n"
"    -c <count>   -- Number of forkers to create\n"
"    -C           -- Chain forks instead of forking from the same process\n"
"                    each time.\n"
"    -r           -- Use rfork(RFPROC | RFNOWAIT | RFTSIGZMB(0))\n",
	    NFORKS);

	exit(1);
}

static void
forkloop(int nforks, bool chain, bool rforkp)
{
	pid_t pid;
	int status;

	while (nforks --> 0) {
		if (rforkp)
			pid = rfork(RFPROC | RFNOWAIT | RFTSIGZMB |
			    RFTSIGFLAGS(0));
		else
			pid = fork();
		if (pid == -1)
			err(1, "fork");
		if (pid == 0) {
			if (!chain)
				_exit(0);
		} else {
			if (chain)
				_exit(0);
			else if (!rforkp) {
				(void)wait(&status);
				if (!WIFEXITED(status) ||
				    WEXITSTATUS(status) != 0)
					err(1, "wait");
			}
		}
	}
	_exit(0);
}

int
main(int argc, char **argv)
{
	struct timespec ts1, ts2;
	pid_t pid;
	long ms;
	int ch, count, nforks, status;
	bool chain, rforkp;

	chain = false;
	count = 1;
	rforkp = false;
	nforks = NFORKS;

	while ((ch = getopt(argc, argv, "Cc:n:r")) != -1)
		switch (ch) {
		case 'C':
			chain = true;
			break;
		case 'c':
			count = atoi(optarg);
			break;
		case 'n':
			nforks = atoi(optarg);
			break;
		case 'r':
			rforkp = true;
			break;
		default:
			usage();
			/* NORETURN */
		}

	if (clock_gettime(CLOCK_MONOTONIC_PRECISE, &ts1) != 0)
		err(1, "clock_gettime");
	for (int i = 0; i < count; i++) {
		pid = fork();
		if (pid == -1)
			err(1, "fork");
		if (pid == 0)
			forkloop(nforks, chain, rforkp);
	}
	if (!chain) {
		while (count --> 0) {
			(void)wait(&status);
			if (!WIFEXITED(status) || WEXITSTATUS(status) != 0)
				err(1, "wait");
		}
	}
	if (clock_gettime(CLOCK_MONOTONIC_PRECISE, &ts2) != 0)
		err(1, "clock_gettime");

	ms = ts2.tv_sec * 1000 + ts2.tv_nsec / 1000000 -
	    (ts1.tv_sec * 1000 + ts1.tv_nsec / 1000000);
	printf("%ldms\n", ms);
	return (0);
}
