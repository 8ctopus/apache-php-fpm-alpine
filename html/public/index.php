<?php

/**
 * List all examples
 */

require_once '../header.php';

echo 'Hello from docker container!' . PHP_EOL . PHP_EOL;

// list current directory files
$it = new RecursiveDirectoryIterator(__DIR__, FilesystemIterator::SKIP_DOTS);

while ($it->valid()) {
    if (!$it->isDot()) {
        $file = $it->getSubPath() .'/'. $it->getSubPathName();

        switch ($it->getSubPathName()) {
            case 'index.php':
            case 'favicon.ico':
                break;

            default:
                echo "<a href=\"{$file}\">{$file}</a>" . PHP_EOL;
                break;
        }
    }

    $it->next();
}

require_once '../footer.php';
