usage()
{
    cat <<__EOF__
Usage: ubench machine -m <machine> -h <host> -i <ipmitool args> -d <root dir>
__EOF__

    exit 1
}

while getopts "d:h:i:m:" FLAG; do
    case ${FLAG} in
    d)
        ROOTDIR=$OPTARG
        ;;
    h)
        HOSTNAME=$OPTARG
        ;;
    i)
        IPMITOOLARGS=$OPTARG
        ;;
    m)
        MACHINE=$OPTARG
        ;;
    *)
        usage
        ;;
    esac
done
