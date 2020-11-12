<html>
<body>
<pre>
    Hello from docker container!

<?php

// list current directory files
$it = new RecursiveDirectoryIterator(__DIR__, FilesystemIterator::SKIP_DOTS);

while ($it->valid()) {
    if (!$it->isDot()) {
        $file = $it->getSubPath() .'/'. $it->getSubPathName();

        echo("    <a href=\"{$file}\">{$file}</a>\n");
    }

    $it->next();
}
