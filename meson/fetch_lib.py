#!/usr/bin/env python3

from sys import argv, exit
from tempfile import NamedTemporaryFile
from urllib.request import urlretrieve
from zipfile import ZipFile
from os.path import isdir, join
from shutil import move

def download_file(url: str):
    with NamedTemporaryFile(suffix=".zip", delete=False) as tmp_file:
        temp_path = tmp_file.name

    urlretrieve(url, temp_path)
    return temp_path

def main(argv: list):
    argv = argv[1:]

    if len(argv) != 4:
        eprint("usage: dest libname unpacked url")
        exit(1)

    dest = argv[0]
    libname = argv[1]
    unpacked = argv[2]
    url = argv[3]

    if isdir(join(dest, libname)):
        return

    zip = ZipFile(download_file(url))
    zip.extractall(path=dest)

    move(join(dest, unpacked), join(dest, libname))

if __name__ == "__main__":
    main(argv)