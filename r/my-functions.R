scaled.plot = function(a, b) {
  p.scale = diff(range(a))/diff(range(b))
  a.vals = a/p.scale
  a.vals = a.vals - min(a.vals)
  b.vals = b - min(b)
  plot(b.vals, type="l", col="blue")
  lines(a.vals, type="l", col="red")
}

model.fun = function(a, index, a.val.name, num.days) {
  a.row=a[index,]
  if(index < (num.days + 1)) {
    NA
  }
  else {
    m=lm(a[(index - num.days):(index - 1), a.val.name] ~ c(1:num.days))
    slope=coefficients(m)[2]
  }
}

recovery.len = function(id, dframe, val.name) {
  start.val = dframe[id, val.name]
  len = NA
  i = id + 1
  while(i < nrow(dframe)) {
    if(dframe[i, val.name] >= dframe[id, val.name]) {
      len = i - id 
      break
    }
    i = i + 1
  }
  len
}

to.gain.len=function(id, dframe, val.name, inc.per) {
  val=dframe[id,val.name]
  len=NA
  gain.val=(val + (val * inc.per))
  found.ids=which(dframe[,val.name] >= gain.val)
  found.ids=found.ids[found.ids > id];
  if(length(found.ids > 0)) {
    len=found.ids[1] - id
  }
  len
}

to.loss.len=function(id, dframe, val.name, loss.per) {
  val=dframe[id,val.name]
  len=NA
  loss.val=(val + (val * loss.per))
  found.ids=which(dframe[,val.name] <= loss.val)
  found.ids=found.ids[found.ids > id];
  if(length(found.ids > 0)) {
    len=found.ids[1] - id
  }
  len
}

percent.diff=function(a, index, val.name, relative.start, relative.end) {
  a.row=a[index,]
  start.ind=(index + relative.start)
  end.ind=(index + relative.end)
  all.len=nrow(a)
  if(start.ind > 0 && start.ind < all.len && end.ind > 0 && end.ind < all.len) {
    val1=a[start.ind, val.name]
    val2=a[end.ind, val.name]
    return(as.numeric((val2 - val1) / val1))
  }
  else {
    return(0)
  }
}


lag.f=function(v, f, start.off, end.off) {
  n.max=max(start.off, end.off)
  n.min=min(start.off, end.off)
  if(n.min > 0) 
    n.min=0
  if(n.max < 0) 
    n.max=0
  i.start=1+abs(n.min)
  i.end=(length(v)-n.max)
  result=c();
  if(i.start > 1) 
    for(i in 1:(i.start-1)) {
      result=c(result, NA)
    }

  for(i in i.start:i.end) {
    result=c(result, f(v[(i+start.off):(i+end.off)]))
  }

  if(i.end < length(v)) 
    for(i in (i.end+1):length(v)) {
      result=c(result, NA)
    }

  result
}
  
