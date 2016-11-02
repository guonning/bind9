#!/bin/sh
#
# Copyright (C) 2008, 2012-2014, 2016  Internet Systems Consortium, Inc. ("ISC")
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# $Id: tests.sh,v 1.4 2008/07/19 00:02:14 each Exp $

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh

DIGOPTS="+tcp +noadd +nosea +nostat +noquest +nocomm +nocmd"

status=0
t=0

echo "I:testing basic ACL processing"
# key "one" should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }


# any other key should be fine
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

cp -f ns2/named2.conf ns2/named.conf
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 reload 2>&1 | sed 's/^/I:ns2 /'
sleep 5

# prefix 10/8 should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

# any other address should work, as long as it sends key "one"
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 127.0.0.1 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 127.0.0.1 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

echo "I:testing nested ACL processing"
# all combinations of 10.53.0.{1|2} with key {one|two}, should succeed
cp -f ns2/named3.conf ns2/named.conf
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 reload 2>&1 | sed 's/^/I:ns2 /'
sleep 5

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

# but only one or the other should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 127.0.0.1 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 axfr -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $tt failed" ; status=1; }

# and other values? right out
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 127.0.0.1 axfr -y three:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

# now we only allow 10.53.0.1 *and* key one, or 10.53.0.2 *and* key two
cp -f ns2/named4.conf ns2/named.conf
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 reload 2>&1 | sed 's/^/I:ns2 /'
sleep 5

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

# should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

# should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.1 axfr -y two:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

# should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.3 axfr -y one:1234abcd8765 -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

echo "I:testing allow-query-on ACL processing"
cp -f ns2/named5.conf ns2/named.conf
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 reload 2>&1 | sed 's/^/I:ns2 /'
sleep 5
t=`expr $t + 1`
$DIG +tcp soa example. \
    	@10.53.0.2 -b 10.53.0.3 -p 5300 > dig.out.${t}
grep "status: NOERROR" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

echo "I:testing EDNS client-subnet ACL processing"
cp -f ns2/named6.conf ns2/named.conf
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 reload 2>&1 | sed 's/^/I:ns2 /'
sleep 5

# should fail
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 axfr -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 || { echo "I:test $t failed" ; status=1; }

# should succeed
t=`expr $t + 1`
$DIG $DIGOPTS tsigzone. \
    	@10.53.0.2 -b 10.53.0.2 +subnet="10.53.0/24" axfr -p 5300 > dig.out.${t}
grep "^;" dig.out.${t} > /dev/null 2>&1 && { echo "I:test $t failed" ; status=1; }

echo "I:testing EDNS client-subnet response scope"
cp -f ns2/named7.conf ns2/named.conf
$RNDC -c ../common/rndc.conf -s 10.53.0.2 -p 9953 reload 2>&1 | sed 's/^/I:ns2 /'
sleep 5

t=`expr $t + 1`
$DIG example. soa @10.53.0.2 +subnet="10.53.0.1/32" -p 5300 > dig.out.${t}
grep "CLIENT-SUBNET.*10.53.0.1/32/0" dig.out.${t} > /dev/null || { echo "I:test $t failed" ; status=1; }

t=`expr $t + 1`
$DIG example. soa @10.53.0.2 +subnet="192.0.2.128/32" -p 5300 > dig.out.${t}
grep "CLIENT-SUBNET.*192.0.2.128/32/24" dig.out.${t} > /dev/null || { echo "I:test $t failed" ; status=1; }

echo "I:exit status: $status"
[ $status -eq 0 ] || exit 1
