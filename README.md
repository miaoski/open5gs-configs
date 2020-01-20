Send SMS over SGs (SMSoS) with Open5GS and Osmo-MSC
===================================================
There are quite a few discussions on Osmocom's mailing list about how to setup
SMS-over-SGs and send/receive SMS from one commercial device (= a regular
cellphone) to another, using Open5GS (= NextEPC) and Osmo-MSC.  However, it is
still a bit challenging to make the configuration right.  This document aims to
be an end-to-end configuration guide to setup a working lab environment.

**N.B.** You need a proper Faraday cage if you have not applied for an experimental spectrum.

Devices and IP
--------------
I have the following devices and IP assignment for the lab.

- Two cellphones with SysmoUSIM (Samsung S5 and Xiaomi Pro 9 in my case)
- BladeRF x115 or B210 (either works very well) with a Leo Bodnar GPSDO
- A laptop with Ubuntu 18.04 LTS
- Antennae that matches the frequency of your choice (850 MHz in my config)

To make things easier, I set `/etc/hosts` like this:
```
127.0.0.1 localhost
127.0.1.1 epc01
127.0.0.2 mme.localdomain mme sgw.localdomain sgw
127.0.0.3 pgw.localdomain pgw
127.0.0.4 hss.localdomain hss
127.0.0.5 pcrf.localdomain pcrf
127.0.0.6 mgw.localdomain mgw
127.0.0.11 gtp.localdomain gtp
127.0.0.11 s1c.localdomain s1c
```

Osmo-MSC is listening to `127.0.0.1`.


BladeRF + GPSDO
---------------
Refer to
[Taming Your VCTCXO](https://github.com/Nuand/bladeRF/wiki/Taming-Your-VCTCXO) and
[VCTCXO Taming via 1 PPS or 10 MHz input](https://www.nuand.com/2016-01-rc1-release/)
to properly set your BladeRF.  The antennae are critical as well.
Although BladeRF x115 only does QPSK for me (while Ettus USRP B210 does 16
QAM), it is good enough for SMS.

Type the commands every time after a reboot:
- `bladeRF-cli -i`
- `set vctcxo_tamer 10MHz` to begin the tuning procedure
- Quit bladeRF-cli and let it run in the background.  1 or 2 minutes of calibration should be more than enough.


srsENB
------
Download and install srsEPC from [their GitHub repo](https://github.com/srsLTE/srsLTE).
There should be no problem if you have a fresh installed Ubuntu 18.04 LTS.
Here are some general tips:

- Use the latest firmware (2.3.2) and the latest FPGA (0.11.0)
- Use a lowlatency Linux kernel (4.15-lowlatency on Ubuntu 18.04 works)
- Set `/sys/devices/system/cpu/cpu[0-9]/cpufreq/scaling_governor` to performance

Edit `/etc/srslte/enb.conf`,
- Change the config files, especially MNC, MCC, eARFCN.  In my case, eARFCN 2525 (band 5, 850MHz).  Cf. http://niviuk.free.fr/lte_band.php
- After setting up Open5GS, `sudo srsenb`


Open5GS
-------
It's quite easy to setup NextEPC as I have upgrade my laptop to Ubuntu 18.04
LTS.  Simply follow the steps here: https://nextepc.org/installation/02-ubuntu/
It is recommended to install from the source code.  However, it is not
mandatory to test SMS.

Open `http://localhost:3000` in a browser and setup IMSI / Ki / OPc for all of your SIM cards.

Tips:
- If PLMN is correct and your phone does not register to the network, check
  whether the APN is `internet`.  It can be `truphone.com` on 33C3 USIMs, and 
  that is not right.
- Wireshark with capture filter `host 127.0.1.100` and display filter `s1ap` to debug.


SMS over SGs
============
There are 3 ways to transmit SMS on a LTE network: SMS over IP (= SMS over
IMS), SMS over SGs (= tunnel it back to a 3G SMS-C) and CSFB.  The community
has already implemented SMSoS.

Use OsmoMSC as SMS-C
--------------------
First, install OsmoMSC for its embedded SMS-C.  Vadim Yanitskiy is working on a
standalone SMS-C, but it is not yet available in the mean time.  Follow the
instructions here to build OsmoMSC from source code.  For the sake of
simplicity, let's assume Osmocom stack is running on 127.0.0.1.

Follow the 
[Build from Source](https://osmocom.org/projects/cellular-infrastructure/wiki/Build_from_Source#Example-completely-build-osmo-bsc-osmo-msc-osmo-sgsn-and-osmo-ggsn)
instructions on Osmocom Wiki, or just be lazy and run `build-osmo-3g.sh` in the
repo.

After building it, copy the configuration files in `./osmocom/` to `/usr/local/etc/osmocom/`.


Run!
====
Run the following commands as `root`.
1. Power on the GPSDO
1. Power on BladeRF and use `bladeRF-cli -i`
   1. `set vctcxo 10MHz`
   1. `print trimdac`
   1. Wait for 1 minute for the signal to stablize
1. Run in terminal 1: `cd /usr/local/etc/osmocom; osmo-hlr -c osmo-hlr.cfg`
1. Run in terminal 2: `cd /usr/local/etc/osmocom; osmo-msc -c osmo-msc.cfg`
1. Run in terminal 3: `systemctl stop open5gs-mmed.service; open5gs-mmed -c /etc/open5gs/mme.yaml` just for easy debugging
1. Run in terminal 4: `srsenb`
1. `telnet localhost 4258` and add IMSI to OsmoHLR (do this only once, to setup all IMSI that you have, cf. https://ftp.osmocom.org/docs/latest/osmohlr-usermanual.pdf)
   1. enable
   1. subscriber imsi 123456789023000 create
   1. subscriber imsi 123456789023000 update msisdn 423
   1. subscriber msisdn 423 update aud3g milenage k deaf0ff1ced0d0dabbedd1ced1cef00d opc cededeffacedacefacedbadfadedbeef
   1. subscriber msisdn 423 show
1. Send SMS over :)


MSISDN and IMSI
---------------
**To clarify**: OsmoHLR is the place to map IMSI to MSISDN.
