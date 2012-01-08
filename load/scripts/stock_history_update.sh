#!/bin/bash
#
# Description: Updates stock history from yahoo data
#
# Input:  filename of ticker records (1st field must be ticker symbols)
# Output:
#  tick-cid:  ticker cid records
#  tick-day-trade:  ticker day trading_info (hi lo mid cls vol)
#
# Warning:  This is fairly brittle as it depends on an unchanging
# record format for financial records from yahoo finance

if [ ! -d "$FINX_HOME" ]
then
  echo "FINX_HOME is not set or is not a directory"
  exit 1
fi

day=`date +%Y-%m-%d`
log="$FINX_HOME/load/stock-history-update-$day.log"


if [ $# -ne 1 ]; then
    echo "usage:  stock_history_update.sh tick-file"
    exit 1
fi

cur_dir=`pwd`
cd $FINX_HOME/load

############################################################
# No need to get cid's, Google/Yahoo take ticker.
#
# For each ticker/company, scrape the google finance html for their cid
# get the html as files
#cat $1 | ruby -ane 'url = "\"http://finance.google.com/finance/historical?q=#{$F[0]}\" -O #{$F[0]}.html"; system("wget -nv #{url}");' 2>> $log

# grep for the cid and output 'em in tick-cid
# cat $1 | ruby -ane "file = \"#{\$F[0]}.html\"; line = \`grep 'name=cid' #{file}\`; line.sub!(/.*value=\\\"(\d+)\\\".*/, '\1'); puts \"#{\$F[0]} #{line}\";" > tick-cid 2>> $log

# For each company/cid, get the stock price history from google as a csv
# history starts from Jan 1 2000 and runs to today
# ruby -ane 'require "time"; \
#   tick = $F[0]; \
#   fr_date = "Jan+1%2C+2000"; \
#   to_date = Time.now.strftime("%b+%d%%2C+%Y"); \
#   url = "\"http://finance.google.com/finance/historical?q=#{tick}&startdate=#{fr_date}&enddate=#{to_date}&output=csv\" -O data/#{tick}.csv"; \
#   system("wget -nv #{url}");' $1 2>> $log

# Same, but from Yahoo
# Note:  Yahoo date months start at 0 (i.e. Jan=0)
ruby -ane 'require "time"; \
  tick = $F[0]; \
  fr_date = "a=0&b=1&c=2000"; \
  to_date = Time.now.strftime("d=%m&e=%d&f=%Y"); \
  url = "\"http://ichart.finance.yahoo.com/table.csv?s=#{tick}&#{to_date}&#{fr_date}&ignore=.csv\" -O data/#{tick}.csv"; \
  system("wget -nv #{url}");' $1 2>> $log

# Cat all csv togethor into one space delimed file
# prepending ticker to each record
# Files come from google/yahoo with following fields:
# Date,Open,High,Low,Close,Volume
awk 'BEGIN { FS = ","; } \
      FNR > 1 { \
        sym = gensub(/[^\/]*\/([^\.]*)\..*$/, "\\1", "s", FILENAME); \
        print sym " " $1 " " $2 " " $3 " " $4 " " $5 " " $6; \
      }' \
      data/*.csv > tmp-tick-day-trade-1 2>> $log

# Write out with formatted/numerically sortable dates
ruby -ane 'require "time"; \
  res = ParseDate.parsedate($F[1]); \
  tm = Time.local(*res); \
  yyyymmdd = tm.strftime("%Y%m%d"); \
  puts "#{$F[0]} #{yyyymmdd} #{$F[2]} #{$F[3]} #{$F[4]} #{$F[5]} #{$F[6]}"' \
  tmp-tick-day-trade-1 > tmp-tick-day-trade-2 2>> $log

# sort it by date, ticker
sort -k 1,1.4 tmp-tick-day-trade-2 > tdt 2>> $log

# Get the latest volume for the ticker
# AND output warnings for tickers that have no last record
cat $1 | ruby -ane 'tick = $F[0]; \
  line = `grep "#{tick}" tdt | tail -1 | cut -d " " -f7`.chop; \
  $stderr.puts "Warning:  check data for ticker #{tick}" if line.length < 1; \
  puts "#{tick} #{line}" if line.length > 0;' > tick-vol 2>> $log

# backup todays files
tar -cjf $day-tdt.bz2 tdt 2>> $log
tar -cjf $day-tick-vol.bz2 tdt 2>> $log

# go back to original dir
cd $cur_dir
