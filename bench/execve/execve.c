#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/wait.h>

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <unistd.h>

static pthread_barrier_t barr;

static void
execve_loop(int fd)
{
	int error, status;
	pid_t pid;

	error = pthread_barrier_wait(&barr);
	if (error != 0 && error != PTHREAD_BARRIER_SERIAL_THREAD)
		errc(1, error, "pthread_barrier_wait");

	for (int i = 0; i < 2500; i++) {
		pid = fork();
		if (pid < 0) {
			if (errno == EAGAIN)
				(void)wait(&status);
			else
				err(1, "fork");
		}
		if (pid == 0) {
			fexecve(fd, (char *[]){ "/usr/bin/true", NULL },
			    (char *[]){ NULL });
			err(1, "fexecve");
		}
	}
	_exit(0);
}

int
main(int argc, char **argv)
{
	pthread_barrierattr_t barrattr;
	size_t ncpusz;
	int error, fd, ncpu, status;
	pid_t pid;

	ncpusz = sizeof(ncpu);
	if (sysctlbyname("kern.smp.cpus", &ncpu, &ncpusz, NULL, 0) != 0)
		err(1, "sysctl(kern.smp.cpus)");

	if ((error = pthread_barrierattr_init(&barrattr)) != 0)
		errc(1, error, "pthread_barrierattr_init");
	if ((error = pthread_barrierattr_setpshared(&barrattr,
	    PTHREAD_PROCESS_SHARED)) != 0)
		errc(1, error, "pthread_barrierattr_setpshared");

	if ((error = pthread_barrier_init(&barr, &barrattr, ncpu)) != 0)
		errc(1, error, "pthread_barrier_init");

	fd = open("/usr/bin/true", O_RDONLY);
	if (fd < 0)
		err(1, "opening /usr/bin/true");

	for (int i = 0; i < ncpu; i++) {
		pid = fork();
		if (pid < 0)
			err(1, "fork");
		if (pid == 0)
			execve_loop(fd);
	}

	for (int i = 0; i < ncpu; i++)
		(void)wait(&status);

	(void)close(fd);
	return (0);
}
