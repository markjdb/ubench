usage()
{
    cat <<__EOF__
Usage: ubench run <job> [-t <tests>]
__EOF__
    exit 1
}

. ${UBENCH_LIBPREFIX}/common.sh

[ $# -eq 1 ] || usage

job=$1
load_job_config $job || warn "failed to load configuration for $job"

set -e

# XXX we need to have a job lock

cd $TREE_PATH
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
MAKEOBJDIRPREFIX=${TREE_OBJDIR} make -s -j $(sysctl -n hw.ncpu) \
    buildworld buildkernel -DNO_CLEAN -DNO_KERNELCLEAN \
    KERNCONF=GENERIC-NODEBUG __MAKE_CONF=/dev/null SRCCONF=/dev/null

ipmitool $MACHINE_IPMITOOL power off

MAKEOBJDIRPREFIX=${TREE_OBJDIR} make -s -j $(sysctl -n hw.ncpu) \
    installworld installkernel \
    KERNCONF=GENERIC-NODEBUG __MAKE_CONF=/dev/null SRCCONF=/dev/null \
    DESTDIR=${MACHINE_ROOTDIR}

ipmitool $MACHINE_IPMITOOL power on

warn "waiting for $JOB_MACHINE to boot..."

while ! ping -c 1 -t 3 ${MACHINE_HOSTNAME} >/dev/null; do
    sleep 1
done

sleep 30 # XXX wait for sshd...

scp -r ${UBENCH_PATH}/bench root@${MACHINE_HOSTNAME}:/tmp
ssh root@${MACHINE_HOSTNAME} "cd /tmp/bench && make"
