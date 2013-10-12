def log(*args) #:nodoc:
  args.unshift(Time.now)
  PP::pp(args.compact, $stdout, 120)
end

def debug(*args) #:nodoc:
  log(*args)
end

def trace(*args) #:nodoc:
  log(*args)
end