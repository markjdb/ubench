usage()
{
    cat <<__EOF__
Usage: ubench run <job>
__EOF__

    exit 1
}

. ${UBENCH_LIBPREFIX}/common.sh

[ $# -eq 1 ] || usage

job=$1
load_job_config $job || warn "failed to load configuration for $job"

set -e

# XXX we need to have a job lock

cd $JOB_SRCTREE
git remote update
if ! git status | grep "Your branch is behind "; then
    # XXX false if we committed locally...
    # XXX add option for git branch
    # XXX add option to abort the run if no new changes are found
    warn "src tree hasn't been modified since the last run"
fi

git pull

# XXX rebuild and run should probably be separate subcommands...
#     for now this is simple though
# XXX make kernel config an (optional) job param, default to GENERIC_NODEBUG
# XXX make src.conf/make.conf optional
MAKEOBJDIRPREFIX=${JOB_OBJDIR} make -s -j $(sysctl -n hw.ncpu) \
    buildworld buildkernel -DNO_CLEAN -DNO_KERNELCLEAN \
    KERNCONF=GENERIC-NODEBUG __MAKE_CONF=/dev/null SRCCONF=/dev/null

ipmitool $MACHINE_IPMITOOL power off

MAKEOBJDIRPREFIX=${JOB_OBJDIR} make -s -j $(sysctl -n hw.ncpu) \
    installworld installkernel \
    KERNCONF=GENERIC-NODEBUG __MAKE_CONF=/dev/null SRCCONF=/dev/null \
    DESTDIR=${MACHINE_ROOTDIR}

ipmitool $MACHINE_IPMITOOL power on

warn "waiting for $JOB_MACHINE to boot..."

sleep 300 # XXX
