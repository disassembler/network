{---
title = "Drupal 8 Developers - Callback to route conversion";
tags = [ "content" ];
uid = "drupal-8-callback-routes";
---}

How to convert drupal 7 callbacks to drupal 8 routes
>>>

With Drupal 8 on the horizon, it's time to start thinking about the practical side of converting a module. This post will detail a very basic conversion of a hook_menu entry to a route controller. The base module to convert will be a hello_world module with three page callbacks, the latter two of which do not have menu entries. The first outputs static text, the second takes a variable from the query string and outputs a string with that variable embedded, and the third returns a JSON encoded structure:

hello_world.module

    <?php
    function hello_world_menu() {
      $items['hello'] = array(
        'title' => 'Hello World',
        'page callback' => 'hello_world',
        'access arguments' => TRUE,
      );
      $items['hello/%'] = array(
        'title' => 'Hello World',
        'page callback' => 'hello_world_age',
        'page arguments' => array(2),
        'access arguments' => TRUE,
        'type' => MENU_CALLBACK,
      );
      $items['json/hello/%'] = array(
        'title' => 'Hello World',
        'page callback' => 'hello_world_age_json',
        'page arguments' => array(3),
        'access arguments' => TRUE,
        'type' => MENU_CALLBACK,
      );
      return $items;
    }
    function hello_world() {
      return "Hello World!";
    }
    function hello_world_age($age) {
      $age = check_plain($age);
      return "Hello World, I am $age today.";
    }
    function hello_world_age_json($age) {
      $age = check_plain($age)
      exit(json_encode(array(
        'string' => "Hello World, I am $age today.",
        'age' => $age,
      )));
    }
    ?>
    
The info file in Drupal 8 is defined using YAML:

hello_world.info.yml:

    name: Hello World
    type: module
    description: 'Hello World test module'
    package: hello
    version: VERSION
    core: 8.x
    
The first step is to define these as routes in a routing.yml file:

hello_world.routing.yml:

    hello_world_hello:
      pattern: '/hello'
      defaults:
        _content: '\Drupal\hello_world\Controller\HelloWorld::hello'
      requirements:
        _access: 'TRUE'
    hello_world_hello_age:
      pattern: '/hello/age/{age}'
      defaults:
        _content: '\Drupal\hello_world\Controller\HelloWorld::helloAge'
      requirements:
        _access: 'TRUE'
    
    hello_world_json_hello_age:
      pattern: '/json/hello/{age}'
      defaults:
        _controller: '\Drupal\hello_world\Controller\HelloWorld::jsonHello'
      requirements:
        _access: 'TRUE'

The first line of a route block is the route_name. Each route should have a unique name, so prefixing with the module name is considered a best practice. The pattern comes from the index of the menu array. This is the path the user puts in their browser. Notice that all parameters must be named in Drupal 8, so wildcards (the `%` character) need to be given a name that will match the parameter name in the callback. The _content attribute specifies the class and method called when this route is matched. The method can return a string, a Drupal render array, or a response object, all of which are injected into the content section of a Drupal site. The _controller method is similar, but the resulting route will not contain the Drupal skeleton. It's useful for returning response objects that aren't part of the Drupal page. In this case, the method is returning a JSON response. Now, a controller class needs to be created to implement the routes in the routing file.

lib/Drupal/hello_world/Controller/HelloWorld.php:

    <?php
    namespace Drupal\hello_world\Controller;
    use
    
    Symfony\Component\HttpFoundation\JsonResponse;
    use Drupal\Component\Utility\String;
    class
    
    HelloWorld {
      public function hello() {
        return "Hello World!";
      }
      public function helloAge($age) {
        $age = String::checkPlain($age);
        return "Hello World, I am $age today.";
      }
      public function jsonHello($age) {
        $age = String::checkPlain($age);
        return new JsonResponse(array(
          'string' => "Hello World, I am $age today.",
          'age' => $age,
        ));
      }
    }
    ?>
    
The first two methods contain the same objects that the original page callbacks contain. In the JSON method, we are now returning a JSON Response object. This is an object that sets the proper headers for a JSON type and encodes the array passed as JSON. To use it, a use statement needs to be declared at the top of the file. Finally, because Drupal 8 follows the PSR-0 naming standard, the namespace needs to be specified as the first line of the class. This particular module is in the namespace `\Drupal\hello_world`. Because our controllers are in a subdirectory, the namespace needs controllers appended at the end. Finally, the hello_world.module can be simplified by removing unused parts:

hello_world.module:

    <?php
    function hello_world_menu() {
      $items['hello'] = array(
        'title' => 'Hello World',
        'route_name' => 'hello_world_hello',
      );
      return $items;
    }
    ?>
    
Because `hello/world/age` and `json/hello/%` are just menu callbacks, they can be completely removed. The hello menu entry now only needs the title and route_name specified. All of the functionality originally found in the callbacks is now part of the HelloWorld controller, so the callbacks can be removed as well. In this example, a conversion may seem tedious, but in future posts we will demonstrate how powerful these controllers can be, covering topics such as dependency injection, creating services, and writing access checks.

More information about the new Drupal 8 routing system can be found in the Drupal Change Notice.
