/*-----------------------------------------------------------------------------
  Init

  Initialization of Styx, should not be edited
  -----------------------------------------------------------------------------*/
{ styx
, styxLib
, styx-themes
, extraConf ? { }
}@args:

rec {

  /* Importing styx library
  */


  /*-----------------------------------------------------------------------------
    Themes setup

    -----------------------------------------------------------------------------*/

  /* list the themes to load, paths or packages can be used
    items at the end of the list have higher priority
  */
  themes = [
    styx-themes.generic-templates
    styx-themes.nix
  ];

  /* Loading the themes data
  */
  themesData = styxLib.themes.load {
    inherit styxLib themes;
    extraEnv = { inherit data pages; };
    extraConf = [ ./conf.nix extraConf ];
  };

  /* Bringing the themes data to the scope
  */
  inherit (themesData) conf lib files templates env;


  /*-----------------------------------------------------------------------------
    Data

    This section declares the data used by the site
    -----------------------------------------------------------------------------*/

  data = with lib; {
    # Loading the index page data
    index = loadFile { file = ./data/index.nix; inherit env; };
    # loading a single page
    about = loadFile { file = ./data/pages/about.md; inherit env; };

    # loading a list of contents
    posts = sortBy "date" "dsc" (loadDir { dir = ./data/posts; inherit env; });

    # menu declaration
    menu = with pages; [
      (about // { navbarTitle = "~/about"; })
      ((head postsList) // { navbarTitle = "~/posts"; })
    ];
  };


  /*-----------------------------------------------------------------------------
    Pages

    This section declares the pages that will be generated
    -----------------------------------------------------------------------------*/

  pages = with lib; rec {

    /* Index page
      Splitting a list of items through multiple pages
      For more complex needs, mkSplitCustom is available
    */
    #index = mkSplit {
    #  title        = "Home";
    #  basePath     = "/index";
    #  itemsPerPage = conf.theme.itemsPerPage;
    #  template     = templates.index;
    #  data         = posts.list;
    #};

    /* Custom index page
      See data/index.nix for the details
    */
    index = {
      title = "sam@samleathers.com ~ $";
      path = "/index.html";
      template = id;
    } // data.index;

    /* About page
      Example of generating a page from imported data
    */
    about = {
      title = "About";
      path = "/about.html";
      template = templates.page.full;
    } // data.about;

    /* Feed page
    */
    feed = {
      title = "Feed";
      path = "/feed.xml";
      template = templates.feed.atom;
      # Bypassing the layout
      layout = id;
      items = take 10 posts.list;
    };

    /* 404 error page
    */
    e404 = {
      path = "/404.html";
      template = templates.e404;
    };

    /* Posts lists */
    postsList = mkSplit {
      title = "Posts";
      basePath = "/posts/index";
      itemsPerPage = 5;
      template = templates.posts-list;
      data = posts.list;
    };

    /* Posts pages
    */
    posts = mkPageList {
      data = data.posts;
      pathPrefix = "/posts/";
      template = templates.post.full;
      #breadcrumbs = [ (head pages.index) ];
    };

  };


  /*-----------------------------------------------------------------------------
    Site rendering

    -----------------------------------------------------------------------------*/

  # converting pages attribute set to a list
  pageList = lib.pagesToList {
    inherit pages;
    default = { layout = templates.layout; };
  };

  site = lib.mkSite {
    inherit pageList;
    files = files ++ [ ./files ];
  };

}
