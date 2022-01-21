{ lib }:
{
  /* URL of the site, must be set to the url of the domain the site will be deployed.
     Should not end with a '/'.
  */
  siteUrl = "https://samleathers.com";

  /* Theme specific settings
     it is possible to override any of the used themes configuration in this set.
  */
  theme = {
    site.title = "sam@samleathers.com ~ $";
  };
}
