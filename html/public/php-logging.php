<?php

echo '<html><pre>';
echo 'test php logging<br><br>';

error_log('test php logging');

error_log('test deprecated');

// deprecated
define("CONSTANT", "Hello world.", true);

echo file_get_contents('/var/log/apache2/error.log');
