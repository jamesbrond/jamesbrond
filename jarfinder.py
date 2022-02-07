import os
import sys
import logging
import argparse
import subprocess

def main():
  parser = argparse.ArgumentParser(description='Searches for the class in all JARs in specified folder.')
  parser.add_argument('-p', '--path', required=True, help="path to the JAR files folder")
  parser.add_argument('-n', '--name', required=True, help="name of the class (or part of it)")
  parser.add_argument('-q', '--quiet', action='store_const', const=logging.NOTSET, dest='logLevel', help="suppress debug messages")
  parser.add_argument('-v', '--verbose', action='store_const', const=logging.WARNING, dest='logLevel', help="increase verbosity level")
  parser.add_argument('-vv', '--very-verbose', action='store_const', const=logging.DEBUG, dest='logLevel', help="increase verbosity to higher level")
  parser.add_argument('--version', action='version', version='%(prog)s 2.0')
  args = parser.parse_args()

  log_level = logging.ERROR if args.logLevel == None else args.logLevel
  logging.basicConfig(format='%(asctime)s [%(levelname)s] %(message)s', level=log_level)
  logger = logging.getLogger('JARFinder')

  logger.debug(args)

  files = os.listdir(args.path)
  for f in files:
    if f.endswith(".jar"):
      logger.debug('found jar file %s', (args.path+'/'+f))

      proc = subprocess.run(
        'jar tf ' + args.path+ '/' + f,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
      )
      output = proc.stdout.decode('utf-8')

      if proc.returncode != 0:
        logger.error(output)
        sys.exit()

      if args.name in output:
        print('match found in ' + f)

if __name__ == "__main__":
  main()

# ~@:-]