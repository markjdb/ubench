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
    local confdir job machine tree

    [ $# -eq 1 ] || return 1

    job=$1
    confdir=${UBENCH_ROOT}/jobs/${job}
    [ -d "${confdir}" ] || return 1
    machine=$(cat ${confdir}/machine)
    tree=$(cat ${confdir}/tree)

    load_machine_config $machine || return 1
    load_tree_config $tree || return 1

    JOB_MACHINE=${machine}
    JOB_TREE=${tree}
}

load_tree_config()
{
    local confdir objdir

    [ $# -eq 1 ] || return 1

    tree=$1
    confdir=${UBENCH_ROOT}/trees/${tree}
    [ -d "${confdir}" ] || return 1

    TREE_OBJDIR=$(cat ${confdir}/objdir)
    TREE_PATH=$(cat ${confdir}/path)
}
