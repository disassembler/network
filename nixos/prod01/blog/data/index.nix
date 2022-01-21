/* Custom index page
   
   Returns a page attribute set, merge the data and the template for improved flexibility
*/
{ conf, templates, lib, ... }:
with lib;
let
  /* Page data 
     Can be customized to fit needs
  */
  name = "Sam Leathers";
  description = ''
    A site about technology
  '';
  social = [ {
    title = "GitHub";
    icon  = "github";
    link  = "https://github.com/disassembler";
  } {
    title = "Email";
    icon  = "envelope";
    link  = "mailto:disasm@gmail.com";
  } ];

  /* template
  */
  content = ''
    <div class="row">
    	<div class="col-sm-3 col-centered">
    		<img alt="profile-picture" class="img-responsive img-circle user-picture" src="${templates.url "/images/profile.jpg"}">
    	</div>
    </div>
    <div class="row">
    	<div class="col-xs-12 user-profile text-center">
    		<h1 id="user-name">${name}</h1>
    	</div>
    </div>
    <div class="row">
    	<div class="col-xs-12 user-social text-center">
        ${mapTemplate (s: ''
          <a href="${s.link}" title="${s.title}"><i class="fa fa-${s.icon} fa-3x" aria-hidden="true"></i></a>
        '') social}
    	</div>
    </div>
    <div class="row">
    	<div class="col-md-4 col-md-offset-4 user-description text-center">
    		<p>${description}</p>
    	</div>
    </div>
  '';
in
  { inherit content; }
