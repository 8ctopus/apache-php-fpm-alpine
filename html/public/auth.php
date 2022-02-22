<?php

if (isset($_SERVER['PHP_AUTH_USER']) && isset($_SERVER['PHP_AUTH_PW'])) {
    require_once '../header.php';
    echo 'You\'re authorized.';
}
else {
    //return response('Unauthorized', 401, ['WWW-Authenticate' => 'Basic']);
    header('WWW-Authenticate: Basic');
}
