<?php
    header('Content-Type: application/json');
if (!isset($_SERVER['PHP_AUTH_USER'])) {
    header('WWW-Authenticate: Basic realm="OpenShift Auth Server"');
    header('HTTP/1.0 401 Unauthorized');
    echo '{"error":"Error message"}';
    exit;
} else {
    if ($_SERVER['PHP_AUTH_USER'] == 'rbo' and $_SERVER['PHP_AUTH_PW'] == 'rbo' ){
        echo '{"sub":"rbo", "name": "Robert Bohne", "email":"Robert.Bohne@ConSol.de"}';
    }else{
        header('HTTP/1.0 401 Unauthorized');
        echo '{"error":"Username & passwort falsch.... "}';
    }
}
?>
