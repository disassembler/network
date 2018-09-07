{ pkgs }:

rec {
  globalDefaults = {
    enabled = 1;
    hidden = false;
    keepnr = 5;
    schedulingshares = 100;
    checkinterval = 3600;
    enableemail = false;
    emailoverride = "";
  };
  mkJobset = { enabled ? 1, hidden ? false, description ? "", nixexprinput, nixexprpath, checkinterval ? 5 * minutes, schedulingshares ? 100, enableemail ? false, emailoverride ? false, keepnr ? 5, inputs }@args: {
    enabled = 1;
    hidden = false;
    emailoverride = "";
    enableemail = false;
    checkinterval = 5 * minutes;
    schedulingshares = 100;
    keepnr = 5;
  } // args;
  mkFetchGithub = value: {
    inherit value;
    type = "git";
    emailresponsible = false;
  };
  minutes = 60;
  hours = 60 * minutes;
  days = 24 * hours;
}
