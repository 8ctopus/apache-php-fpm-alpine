<?php

/**
 * Simple example that shows how to use composer
 * In this case we include [Whoops](https://github.com/filp/whoops) which is a php error handler
 */

$autoLoad = '../vendor/autoload.php';

if (!file_exists($autoLoad)) {
    echo 'please run "docker exec web composer install" and refresh the page';
    exit;
}

// include composer dependencies
require_once $autoLoad;

// create whoops object
$whoops = new \Whoops\Run();
$whoops->pushHandler(new \Whoops\Handler\PrettyPageHandler);
$whoops->register();

// let's generate a division by zero to showcase what whoops does
$a = 1;
$b = 0;

$c = $a / $b;
