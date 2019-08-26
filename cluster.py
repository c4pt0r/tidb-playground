#!/usr/bin/env python3
import os
import sys
import yaml
import wget
import tarfile
import shutil
from yaml import Loader, Dumper

LINUX_BIN_URL = 'http://download.pingcap.org/tidb-latest-linux-amd64.tar.gz'

def check_binary_exists():
    os.chdir(os.path.dirname(__file__))
    tidb_path = os.path.join(os.getcwd(),'bin', 'tidb-server')
    tikv_path = os.path.join(os.getcwd(),'bin', 'tikv-server')
    pd_path = os.path.join(os.getcwd(),'bin', 'pd-server')
    return os.path.isfile(tidb_path) and os.path.isfile(tikv_path) and os.path.isfile(pd_path)

def parse_conf(conf_file):
    with open(conf_file) as fp:
       content = fp.read()
       conf = yaml.load(content, Loader = Loader)
       return conf
    return None

def download_and_extract_binary():
    print("start download tidb binaries...")
    try:
        if not os.path.isfile('tidb-latest-linux-amd64.tar.gz'):
            wget.download(LINUX_BIN_URL)
        print("download finish")
        untar_binary()
    except:
        print("download failed")
        sys.exit(-1)

def untar_binary():
    os.chdir(os.path.dirname(__file__))
    tmp = os.path.join(os.getcwd(),'.tmp')
    try:
        tar = tarfile.open('tidb-latest-linux-amd64.tar.gz')
        tar.extractall(path = tmp)
        tar.close()
    except:
        print("untar failed")
        sys.exit(-1)
    shutil.move(os.path.join(tmp, 'tidb-latest-linux-amd64', 'bin'), os.getcwd())

# return (context, pid)
def run(context, command):
    pass 

def kill(pid):
    pass

def check_port(addr)

def usage():
    print('cluster [start|stop|clean]')

# command handler
def handle_start():
    pass

def handle_stop():
    pass

def handle_clean():
    pass

def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == 'start':
            handle_start()
        elif sys.argv[1] == 'stop':
            handle_stop()
        elif sys.argv[1] == 'clean':
            handle_clean()
    else:
        usage()

if __name__ == '__main__':
    main()
