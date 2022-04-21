<?php

/**
 * Simple example that shows how to use composer
 * In this case we include [Dompdf](https://github.com/dompdf/dompdf) which is a PDF generator
 */

use Dompdf\Dompdf;

require '../vendor/autoload.php';

$dompdf = new Dompdf();

$dompdf->setPaper('A4', 'portrait');

$dompdf->loadHtml('<h1>hello from Docker container!</h1>');

// render html as pdf
$dompdf->render();

// output pdf to browser
$dompdf->stream('hello.pdf', [
    'compress' => true,
    'Attachment' => false,
]);
