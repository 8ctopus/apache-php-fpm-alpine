<?php

use Dompdf\Dompdf;

require '../vendor/autoload.php';

$dompdf = new Dompdf();

$dompdf->setPaper('A4', 'portrait');

$dompdf->loadHtml('<h1>hello from Docker container!</h1>');

// render html as pdf
$dompdf->render();

// output the generated PDF to browser
$dompdf->stream();
