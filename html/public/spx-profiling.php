<?php

/**
 * Test php spx profiler
 */

require_once '../header.php';

echo '<a href="/?SPX_KEY=dev&SPX_UI_URI=/" target="_blank">SPX control panel</a>' . PHP_EOL . PHP_EOL;

main();

function main() : void
{
    echo __METHOD__ .'... '. delta_time() . PHP_EOL . PHP_EOL;

    slowme_100();
    slowme_200();
    slowme_400();

    echo __METHOD__ .' - OK - '. delta_time() . PHP_EOL;
}

function slowme_100() : void
{
    echo __METHOD__ .'... '. delta_time() . PHP_EOL;

    usleep(100000);

    echo __METHOD__ .' - OK - '. delta_time() . PHP_EOL . PHP_EOL;
}

function slowme_200() : void
{
    echo __METHOD__ .'... '. delta_time() . PHP_EOL;

    usleep(200000);

    echo __METHOD__ .' - OK - '. delta_time() . PHP_EOL . PHP_EOL;
}

function slowme_400() : void
{
    echo __METHOD__ .'... '. delta_time() . PHP_EOL;

    usleep(400000);

    echo __METHOD__ .' - OK - '. delta_time() . PHP_EOL . PHP_EOL;
}

function delta_time() : int
{
    global $base;

    if (!isset($base)) {
        $base = hrtime(true);
        return 0;
    }

    return hrtime(true) - $base;
}
