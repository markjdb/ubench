warn()
{
    echo "ubench: $1" >&2
}

load_machine_config()
{
    local confdir machine

    [ $# -eq 1 ] || return 1

    machine=$1
    confdir=${UBENCH_ROOT}/machines/${machine}
    [ -d "${confdir}" ] || return 1
    MACHINE_HOSTNAME=$(cat ${confdir}/hostname)
    MACHINE_IPMITOOL=$(cat ${confdir}/ipmitool)
    MACHINE_ROOTDIR=$(cat ${confdir}/rootdir)
}

load_job_config()
{
    local confdir job machine

    [ $# -eq 1 ] || return 1

    job=$1
    confdir=${UBENCH_ROOT}/jobs/${job}
    [ -d "${confdir}" ] || return 1
    machine=$(cat ${confdir}/machine)
    
    load_machine_config $machine || return 1

    # XXX this pattern is ugly.
    JOB_BENCHMARKS=$(cat ${confdir}/benchmarks)
    JOB_MACHINE=${machine}
    JOB_SRCTREE=$(cat ${confdir}/srctree)
    if [ -f ${confdir}/objdir ]; then
        JOB_OBJDIR=$(cat ${confdir}/objdir)
    else
        JOB_OBJDIR=/usr/obj
    fi
}
