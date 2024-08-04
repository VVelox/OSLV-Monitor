# OSLV-Monitor
OS level virtualization monitoring extend

## Install

#### FreeBSD

```shell
pkg install p5-JSON p5-Mime-Base64 p5-Clone
perl Makefile.pl
make
make test
make install
```

#### Debian

```shell
apt-get install libjson-perl libclone-perl libmime-base64-perl
perl Makefile.pl
make
make test
make install
```
