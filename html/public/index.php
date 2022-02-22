<?php

require_once '../header.php';

echo 'Hello from docker container!' . PHP_EOL . PHP_EOL;

// list current directory files
$it = new RecursiveDirectoryIterator(__DIR__, FilesystemIterator::SKIP_DOTS);

while ($it->valid()) {
    if (!$it->isDot()) {
        $file = $it->getSubPath() .'/'. $it->getSubPathName();

        echo "<a href=\"{$file}\">{$file}</a>" . PHP_EOL;
    }

    $it->next();
}

require_once '../footer.php';
