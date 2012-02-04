#!/bin/bash
# script to retrieve yahoo finance pages for each ticker
# scrape for specific data and write to new file
# NOTE:  Run from dir containing the tick-cap file

if [ $# -ne 1 ]; then
    echo "usage:  stock_detail_update.sh tick-file"
    exit 1
fi

tick_list=`cut -f1 -d' ' $1`

for tick in $tick_list; do
  wget -nv "http://finance.yahoo.com/q/ks?s=$tick" -O data/$tick.html;
  shares=`grep 'Shares Outstanding' data/$tick.html | sed 's/\(^.*Shares Outstanding[^y]*yfnc_tabledata1">\)\([^<]*\)<.*$/\2/g'`
  div=`grep 'Forward Annual Dividend Rate' data/$tick.html | sed 's/\(^.*Forward Annual Dividend Rate[^y]*yfnc_tabledata1">\)\([^<]*\)<.*$/\2/g'`
  echo "$tick $div $shares" >> tick-div
done

sed 's/&nbsp;//g' tick-div > t-div
sed 's/%//g' t-div > tdiv

rm t-div tick-div
