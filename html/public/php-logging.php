<?php

/**
 * Test php logging
 */

require_once '../header.php';

echo 'test php logging' . PHP_EOL . PHP_EOL;

error_log('test php logging');

// deprecated
define("CONSTANT", "Hello world.", true);

echo file_get_contents('/var/log/apache2/error_log');
