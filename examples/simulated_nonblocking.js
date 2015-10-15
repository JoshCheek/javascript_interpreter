var startTime = new Date();

var printTimeExecuted = function(description) {
  var currentTime       = new Date();
  var millisecondsTaken = currentTime - startTime
  console.log(description + " " + millisecondsTaken);
};

var first  = function() { printTimeExecuted("first")  };
var second = function() { printTimeExecuted("second") };
var third  = function() { printTimeExecuted("third")  };

// this one is async b/c it provides a callback
// should print 2 seconds later
setTimeout(first, 2000);

// this one saves the current callstack as the callback
// should print 1 second later, b/c the first setTimeout is async
setTimeout(1000);
second();

// this one is async b/c it provides a callback
// should print 3 seconds later, b/c it won't run until the second returns
setTimeout(third, 2000);
