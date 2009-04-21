#!/usr/bin/env python
import os, sys

def install():
    build_darling = False
    # TODO: this is really ugly, but works for now.
    python_version = sys.version[:3]
    system_target = '/usr/lib/python'+python_version+'/site-packages'
    target = '/usr/share/zohmg'

    # check for rootness.
    if os.geteuid() != 0:
        print "you need to be root. please sudo."
        sys.exit(1)
    print "installing!"

    # mkdir.
    create_share_dir(target)

    # darling.
    if build_darling:
        build_darling(target)
    else:
        copy_bundle("pre-built darling jar","lib/darling-*.jar",target)

    # thrift & hbase
    # TODO: fix this better.
    # copies thrift egg.
    copy_bundle("bundled thrift egg","lib/thrift-*.egg",system_target)
    # copies hbase egg.
    copy_bundle("bundled hbase egg","lib/hbase-*.egg",system_target)
    # copies hbase thrift interface.
    copy_bundle("bundled hbase thrift interface","lib/Hbase.thrift",target)


def setup():
    print
    print "installing zohmg: python setup.py install"
    r = os.system('python setup.py install > tmp/zohmg-install.log')
    if r != 0:
        print "errors?!"
        print "try again, it could work the second (or third) time."
        sys.exit(r)
    os.system("egrep '(Installing|Copying) zohmg' tmp/zohmg-install.log")
    # clean up.
    os.system("rm -rf build dist zohmg.egg-info")

def create_share_dir(dir):
    if not os.path.exists(dir):
        os.system('mkdir ' + dir)

# not used atm; user would have to specify classpath == jobbigt.
def build_darling(target):
    print 'building java hook-ups'
    r = os.system('cd java/darling; ant')
    if r != 0:
        # fail!
        print 'problems building darling!'
        print 'hey, I need to know where to find jars for hbase, hadoop and hadoop streaming.'
        print 'please add them to $CLASSPATH and try again.'
        sys.exit(r)
    os.system("cp -v java/darling/build/darling-.jar " + target)

# copies bundle (file) to target, printing msg.
def copy_bundle(msg,file,target):
    print "copying",msg
    os.system("cp -v %s %s" % (file,target))


if __name__ == "__main__":

    install()
    setup()

    print
    print "ok, that should do it!"
    print "now try this:"
    print "$> zohmg help"
    print