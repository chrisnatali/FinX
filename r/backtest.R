bt.pool = 10000
bt.positions = as.data.frame(matrix(nrow=0, ncol=4))
bt.ledger = as.data.frame(matrix(nrow=0, ncol=7))
bt.day.ledger = as.data.frame(matrix(nrow=0, ncol=3))

# simulate buying and selling after sell.i days
bt.sim = function(day.buys, orig.tdt, sell.i) {
  for(i in 1:length(day.buys)) {

    # sell off any positions for the day
    if(nrow(bt.positions) > 0) {
      bt.sim.sell(orig.tdt, i, sell.i)
    }

    if(!is.null(day.buys[[i]])) {
      day.list=day.buys[[i]]
      
      # use only the buys with data within the selling range
      valid.days=((day.list$id+sell.i) <= nrow(orig.tdt))
      valid.days=(valid.days & (orig.tdt$sym[day.list$id+sell.i]==day.list$sym))
      day.list.f=day.list[valid.days,]
      
      if(nrow(day.list.f) > 1) {
        bt.sim.buy(day.list.f, i)
      }

    }
    pos.total=sum(bt.positions$shares * orig.tdt$op[bt.positions$tdt.id])
    day.ledger=data.frame(day=i, pool=bt.pool, positions=pos.total)
    assign("bt.day.ledger", rbind(bt.day.ledger, day.ledger), envir=.GlobalEnv)
  }
}

bt.sim.sell = function(orig.tdt, day.i, sell.i) {
  
  # get positions to be sold based on num days held
  sell.pos=bt.positions[(day.i-bt.positions$day.num)==sell.i,]

  buy.tdt=orig.tdt[sell.pos$tdt.id,] 
  sell.tdt=orig.tdt[(sell.pos$tdt.id+sell.i),]

  # calculate total sale and add it back to pool
  rev=sum(sell.pos$shares * sell.tdt$cls)
  assign("bt.pool", (bt.pool + rev), envir=.GlobalEnv)

  # record the transactions
  sell.ledg=data.frame(sym=sell.tdt$sym, orig.price=buy.tdt$op, shares=sell.pos$shares, buy.day=buy.tdt$day, sell.day=sell.tdt$day, sell.price=sell.tdt$cls, tdt.id=sell.tdt$id)
  assign("bt.ledger", rbind(bt.ledger, sell.ledg), envir=.GlobalEnv)

  # update the positions
  assign("bt.positions", bt.positions[(day.i-bt.positions$day.num)!=sell.i,], envir=.GlobalEnv)

}
    
bt.sim.buy = function(buy.tdt, day.i) {

  # allocate the available pool to new positions
  num.buys=min(10, nrow(buy.tdt))
  amt.per=bt.pool/num.buys

  # create the positions
  buy.tdt.a=buy.tdt[1:num.buys,]
  buy.shares=floor(amt.per/buy.tdt.a$op)
  new.pos = data.frame(sym=buy.tdt.a$sym, shares=buy.shares, day.num=day.i, tdt.id=buy.tdt.a$id)
  assign("bt.positions", rbind(bt.positions, new.pos), envir=.GlobalEnv)
  
  # update the pool
  cost=sum(buy.shares * buy.tdt.a$op)
  assign("bt.pool", (bt.pool - cost), envir=.GlobalEnv)

}

o.v.test = function(td.set, i.set, b.i, s.i) {
  for(i in i.set) {
    # b.price = max(td.set$op[i+b.i], td.set$cls[i+b.i])
    b.price = td.set$op[i+b.i]
    shares = floor(bt.pool/b.price)
    cost = shares*b.price
    # s.price = min(td.set$op[i+s.i], td.set$cls[i+s.i])
    s.price = td.set$cls[i+s.i]
    revenue = shares * s.price
    ledger.rec = data.frame(sym=td.set$sym[i], orig.price=b.price, shares=shares, orig.day=td.set$day[i+b.i], sell.day=td.set$day[i+s.i], sell.price=s.price)
    assign("bt.ledger", rbind(bt.ledger, ledger.rec), envir=.GlobalEnv)
    assign("bt.pool", (bt.pool + (revenue - cost)), envir=.GlobalEnv)
  }
}
    
bt.sell.positions = function(sdi, per.gain, max.dur) {
  kept.ids= c()
  n.positions = nrow(bt.positions)
  if(n.positions > 0) {
  for(i in 1:n.positions) {
    pos = bt.positions[i,]
    orig.price = pos$price
    cur = sdi[sdi$sym==pos$sym,]
    cur.price = cur$op
    days.held = cur$id - pos$day.id
    cur.diff = cur.price - orig.price
    #print(c("sym", pos$sym))
    #print(c(cur.diff, orig.price, per.gain, days.held, max.dur))
    if (((cur.diff/orig.price) > per.gain) || (days.held >= max.dur)) {
      bt.sell(pos, cur)
    }
    else {
      kept.ids = c(kept.ids, i)
    }
  } 
  assign("bt.positions", bt.positions[kept.ids,], envir=.GlobalEnv)
  }
}

bt.sell = function(orig.pos, cur.pos) {
  ledger.rec = data.frame(sym=orig.pos$sym, orig.price=orig.pos$price, shares=orig.pos$shares, 
                          orig.day=orig.pos$day.id, sell.day=cur.pos$id, 
                          sell.price=cur.pos$op)
  sell.rev = (ledger.rec$sell.price * ledger.rec$shares)
  assign("bt.ledger", rbind(bt.ledger, ledger.rec), envir=.GlobalEnv)
  assign("bt.pool", (bt.pool + sell.rev), envir=.GlobalEnv)
}

bt.buy.positions = function(sdi, long.slope, short.drop, max.positions) {
  pos.left = max.positions - (nrow(bt.positions))
  if((pos.left > 0) && (bt.pool > 0)) {
    match.sdi = sdi[!is.na(sdi$sl.50) & sdi$sl.50 > long.slope & !is.na(sdi$last.diff) & sdi$last.diff < short.drop,]
    match.sdi = match.sdi[order(match.sdi$last.diff, decreasing=FALSE), ]
    for(i in 1:pos.left) {
      if(nrow(match.sdi) >= i) {
        this.sd = match.sdi[i,]
        amt.for.pos = bt.pool / pos.left
        if(this.sd$op < amt.for.pos) {
          pos.shares = floor(amt.for.pos / this.sd$op)
          new.pos = data.frame(sym=this.sd$sym, shares=pos.shares, day.id=this.sd$id, price=this.sd$op)
          cost = this.sd$op * pos.shares
          assign("bt.positions", rbind(bt.positions, new.pos), envir=.GlobalEnv)
          assign("bt.pool", (bt.pool - cost), envir=.GlobalEnv)
        }
      }
    }
  }
}
