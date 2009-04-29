#!/bin/sh

# outline
# - set default options
# - parse options
# - check for programs needed
# - for each sw
#   - download
#   - maybe patch
#   - maybe ant package


# helpers.
function usage() {
    echo "Usage: $(basename $0) [options]"
    echo "Options:"
    echo "    --download-only      Only download software, do not build."
    echo "    --files=FILES        Directory with already downloaded files."
    echo "                         Usually resides in /tmp/zohmg-deps.XXXXX."
    echo "    --hadoop-dir=HADOOP  Changes Apache Hadoop installation dir to HADOOP."
    echo "    --hbase-dir=HBASE    Changes Apache HBase installation dir to HBASE."
    echo "    --hadoop-only        Installs only Apache Hadoop."
    echo "                         Cannot be used with --hbase-only."
    echo "    --hbase-only         Installs only Apache HBase."
    echo "                         Cannot be used with --hadoop-only."
    echo "    --help               Prints this help and exits."
    echo "    --prefix=PREFIX      Changes installation prefix to PREFIX."
    echo "                         Defaults to /opt."
}


# set default variables.
prefix="/opt"
hadoop_tar="hadoop-0.19.1.tar.gz"
patch_1722="HADOOP-1722-branch-0.19.patch"
patch_5450="HADOOP-5450.patch"
hbase_tar="hbase-0.19.1.tar.gz"
hadoop_release="http://mirrors.ukfast.co.uk/sites/ftp.apache.org/hadoop/core/hadoop-0.19.1/$hadoop_tar"
hadoop_1722="https://issues.apache.org/jira/secure/attachment/12401426/$patch_1722"
hadoop_5450="https://issues.apache.org/jira/secure/attachment/12401846/$patch_5450"
hbase_release="http://mirrors.ukfast.co.uk/sites/ftp.apache.org/hadoop/hbase/hbase-0.19.1/$hbase_tar"


# parse arguments.
while [ $1 ]; do
    opt=$(echo $1 | sed 's/=.*//')
    arg=$(echo $1 | sed 's/.*=//')
    case $opt in
        "--download-only")
            download_only=true
            ;;
        "--files")
            files="$arg"
            ;;
        "--hadoop-only")
            if [ $hbase_only ]; then
                echo "Error: --hbase-only and --hadoop-only used at the same time."
                usage
                exit 1
            fi
            hadoop_only=true
            ;;
        "--hbase-only")
            if [ $hadoop_only ]; then
                echo "Error: --hbase-only and --hadoop-only used at the same time."
                usage
                exit 1
            fi
            hbase_only=true
            ;;
        "--hadoop-dir")
            hadoop="$arg"
            ;;
        "--hbase-dir")
            hbase="$arg"
            ;;
        "--help")
            usage
            exit 0
            ;;
        "--prefix")
            prefix="$arg"
            ;;
        *)
            if [ ! "x" = "x$opt" ]; then
                echo "Unknown argument: $opt"
                usage
                exit 1
            fi
            ;;
    esac
    shift
done


# set paths.
[ "x" = "x$hadoop" ] && hadoop="$prefix/hadoop"
[ "x" = "x$hbase" ] && hbase="$prefix/hbase"


# check for necessary programs.
echo "Checking for necessary programs..."
for command in "ant -version" "patch --version" "wget --version"; do
    program=$(echo $command | sed 's/ .*//')
    printf "Checking for $program... "
    $command &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Missing program: $program not found."
        exit 1
    fi
    echo "ok."
done


# download or use already existing files.
if [ "x" = "x$files" ]; then
    # create temporary directories for downloads.
    printf "Creating temporary directory... "
    files=$(mktemp -d /tmp/zohmg-deps.XXXXXX)
    mkdir -p $files/patches
    echo "done."
    printf "Downloading files... "
    # release files.
    cd $files
    wget $hadoop_release &>/dev/null
    wget $hbase_release &>/dev/null
    # download patches.
    cd patches
    wget $hadoop_1722 &>/dev/null
    wget $hadoop_5450 &>/dev/null
    echo "done."
else
    printf "Using previously downloaded files in $files... "
    for file in "patches/$patch_1722" "patches/$patch_5450" "$hadoop_tar" "$hbase_tar"; do
        ls $files/$file &>/dev/null
        if [ $? -ne 0 ]; then
            echo
            echo "Error: Could not find file $files/$file."
            exit 1
        fi
    done
    echo "ok."
fi


# stop if --download-only was supplied.
if [ "$download_only" = "true" ]; then
    echo "Files downloaded to $tmpdir ."
    exit 0
fi


# install.
echo "Installing..."

# check permissions.
for dir in "$hadoop" "$hbase"; do
    mkdir -p "$dir"
    if [ $? -ne 0 ]; then
        echo "Error: Could not create $dir."
        exit 1
    fi
done

# hadoop
printf "Extracting Apache Hadoop... "
mkdir -p $hadoop
tar zxf $files/hadoop-0.19.1.tar.gz -C $hadoop
echo "done."
cd $hadoop
for patch in "$patch_1722" "$patch_5450"; do
    num=$(echo $patch | sed 's/HADOOP-\(.{4}\).*/\1/')
    printf "Applying patch HADOOP-$num... "
    patch -p0 < "$files/patches/$patch"
    echo "done."
done

# hbase.
printf "Extracting Apache HBase... "
mkdir -p $hbase
tar zxf $files/hbase-0.19.1.tar.gz -C $hbase
echo "done."


# configuration?
echo "Everything installed."
echo "Edit the following files to configure Hadoop and HBase:"
echo "* $hadoop/conf/hadoop-env.sh"
echo "* $hadoop/conf/hadoop-site.xml"
echo "* $hbase/conf/hbase-env.sh"
echo "* $hbase/conf/hbase-site.xml"