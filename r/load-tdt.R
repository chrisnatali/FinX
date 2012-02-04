tdt=read.table("tdt")
names(tdt)=c("sym", "day", "op", "hi", "lo", "cls", "vol")
sym.new=c(1, which(tdt$sym[-1] != tdt$sym[-nrow(tdt)])+1)
sym.lens=c(diff(sym.new), nrow(tdt)-(sym.new[length(sym.new)]-1))
i.sym=rep(sym.new, sym.lens)
o.sym=unlist(sapply(sym.lens, function(n) {0:(n-1)}))
chg=c(NA, (tdt$cls[2:nrow(tdt)]-tdt$cls[1:(nrow(tdt)-1)])/tdt$cls[1:(nrow(tdt)-1)])
tdt$i.sym=i.sym
tdt$o.sym=o.sym
tdt$chg=chg
tdt[tdt$o.sym==0, "chg"]=NA
sl.20=c(rep(NA, 20), sapply(21:nrow(tdt), function(n) { m=lm(tdt$cls[(n-20):(n-1)]~c(1:20)); coefficients(m)[2]/tdt$cls[n-20]*100 }));
tdt$sl.20=sl.20
tdt[tdt$o.sym<21, "sl.20"]=NA                            
ma.200=c(rep(NA, 200), sapply(201:nrow(tdt), function(n) { mean(tdt$cls[(n-200):(n-1)]) } ))
tdt$ma.200=ma.200
tdt[tdt$o.sym<201, "ma.200"]=NA                            
tdt$id=1:nrow(tdt)
day.f=factor(tdt$day)
qqq=tdt[tdt$sym=="QQQ",]
q.sl.50=c(rep(NA, 50), sapply(51:nrow(qqq), function(n) { m=lm(qqq$cls[(n-50):(n-1)]~c(1:50)); coefficients(m)[2]/qqq$cls[n-50]*100 }));

# Find the outlier tickers (used as a negative filter)
split.syms=unique(tdt$sym[tdt$o.sym != 0 & (tdt$chg > 0.55 | tdt$chg < -0.55)])

# Find the "buy" tickers/days via iterating over tdt by day
day.ticks=by(tdt, day.f, function(x) { q=x[x$sym=="QQQ",];  if((nrow(q)==1) && !is.na(tdt$ma.200[q$id-1]) && (tdt$cls[q$id-1] > tdt$ma.200[q$id-1]) && (nrow(x) > 2)) { ticks=x[!is.na(x$ma.200) & (x$sl.20 > 0.05) & (tdt$chg[x$id-1] < -0.04) & !(x$sym %in% split.syms),]; ticks[sample(1:nrow(ticks), min(10, nrow(ticks))),] } else { x[FALSE,] } })
save.image()
