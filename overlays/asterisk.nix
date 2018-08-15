self: super: 
{
  pjsip = super.callPackage ./asterisk/pjsip.nix {};
  jansson = super.callPackage ./asterisk/jansson.nix {};
  asterisk = super.callPackage ./asterisk { pjsip = self.pjsip; };
}
