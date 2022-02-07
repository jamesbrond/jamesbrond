#!/usr/bin/env python3
import os
import sys
import errno
import argparse
import subprocess

def _mkdir(newdir):
	try:
		os.makedirs(newdir)
	except OSError as exc:
		if exc.errno != errno.EEXIST or os.path.isdir(newdir):
			raise

parser = argparse.ArgumentParser(description='Java Decompiler Hack')
parser.add_argument('-c', '--classpath', metavar='CLASSPATH', required=True, help='Path where class to be decompiled are')
parser.add_argument('-jd', '--jdjarpath', metavar='JD', required=True, help='Path to jd-cli.jar, if not defines jd-cli.jar must be in Java Library Path. https://github.com/kwart/jd-cmd')
parser.add_argument('-s', '--srcpath', metavar='SRCPATH', required=False, help='Path where decompiled java will be placed (default src)')

args = parser.parse_args()
classpath = args.classpath
jd = args.jdjarpath
src = args.srcpath

if not os.path.exists(classpath) or not  os.path.isdir(classpath):
	print('CLASSPATH does not exist or is not a valid folder')
	sys.exit(192)

if not src:
	src = 'src'

_mkdir(src)

with open('jd.log', 'wb') as jd_cmd_out:
	for root, subdirs, files in os.walk(classpath):
		print(32 * '-', '\nFolder: ', root)
		for filename in files:
			if filename.endswith('.class'):
				print('\t', filename)
				subprocess.call(['java.exe', '-jar', jd, os.path.join(root, filename), '--outputDir', os.path.join(src, root.replace(classpath, '').lstrip(os.sep))], stdout=jd_cmd_out, stderr=jd_cmd_out)

print(32 * '-', 'done\ncheck "jd.log" file for jd-cli output');

# ~@:-]