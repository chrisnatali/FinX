# Select tdt records where price trend is up (via 20 day lin. regression slope)
# AND yesterday's chg was down.  Modify up/down values as needed.
buy.ticks=by(tdt[2:nrow(tdt),], day.f[2:nrow(tdt)], function(x) { x[!is.na(x$ma.200) & (x$sl.20 > 0.10) & (x$sym!="WFC" & x$sym!="C") & (tdt$chg[x$id-1] < -0.04) & (((x$id+10) < nrow(tdt)) & tdt$sym[x$id]==tdt$sym[x$id+10]),]; })

# Same as above, but when trend is down, yesterday's chg was up.
sell.ticks=by(tdt[2:nrow(tdt),], day.f[2:nrow(tdt)], function(x) { x[!is.na(x$ma.200) & (x$sl.20 < -0.10) & (x$sym!="WFC" & x$sym!="C") & (tdt$chg[x$id-1] > 0.04) & (((x$id+10) < nrow(tdt)) & tdt$sym[x$id]==tdt$sym[x$id+10]),]; })

# Calculate an "averaged" revenue generated from selected positions held for some time
buy.rev=sapply(1:length(buy.ticks), function(n) { x=buy.ticks[[n]]; if(!is.null(x)) { assign("dt.sum", dt.sum+sum((((tdt$cls[x$id+3]-x$op)/x$op)*(100/nrow(x)))), envir=.GlobalEnv); dt.sum } else { dt.sum } }, simplify=TRUE)

# Same as above, but for shorted positions
sell.rev=sapply(1:length(sell.ticks), function(n) { x=sell.ticks[[n]]; if(!is.null(x)) { assign("dt.sum", dt.sum+sum((((x$op-tdt$cls[x$id+3])/x$op)*(100/nrow(x)))), envir=.GlobalEnv); dt.sum } else { dt.sum } }, simplify=TRUE)
