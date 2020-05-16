<?php

if (isset($_SERVER['PHP_AUTH_USER']) && isset($_SERVER['PHP_AUTH_PW'])) {
    echo('you\'re authorized');
}
else {
    //return response('Unauthorized', 401, ['WWW-Authenticate' => 'Basic']);
    header('WWW-Authenticate: Basic');
}

