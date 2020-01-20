#!/bin/bash -e

sudo apt install shtool automake autoconf
sudo apt install libortp-dev libpcsclite-dev libtalloc-dev libsctp-dev libmnl-dev libdbi-dev libdbd-sqlite3 libsqlite3-dev sqlite3 libc-ares-dev libgnutls28-dev
sudo apt install libsmpp34-dev dahdi dahdi-source

osmo_src=$HOME/osmo/src
mkdir -p $osmo_src

cd $osmo_src
test -d libosmocore || git clone git://git.osmocom.org/libosmocore
cd libosmocore
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
test -d libosmo-abis || git clone git://git.osmocom.org/libosmo-abis
cd libosmo-abis
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/libosmo-netif
cd libosmo-netif
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/libosmo-sccp
cd libosmo-sccp
test -f configure || autoreconf -fi
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/libsmpp34
cd libsmpp34
test -f configure || autoreconf -fi
./configure
make
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/osmo-mgw
cd osmo-mgw
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/libasn1c
cd libasn1c
test -f configure || autoreconf -fi
./configure
make
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/osmo-iuh
cd osmo-iuh
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/osmo-hlr
cd osmo-hlr
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/osmo-msc
cd osmo-msc
test -f configure || autoreconf -fi
./configure --enable-iu
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/osmo-ggsn
cd osmo-ggsn
test -f configure || autoreconf -fi
./configure
make -j5
make check
sudo make install
sudo ldconfig

cd $osmo_src
git clone git://git.osmocom.org/osmo-sgsn
cd osmo-sgsn
test -f configure || autoreconf -fi
./configure --enable-iu
make -j5
make check
sudo make install
sudo ldconfig

export LD_LIBRARY_PATH="/usr/local/lib" 
export PATH="$PATH:/usr/local/bin" 
which osmo-msc
osmo-msc --version
