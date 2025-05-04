<?php
$host='Localhost';
$user='root';
$pass='';
$db='clinic';
try{
    $polaczenie= new PDO("mysql:host={$host};dbname={$db};charset=utf8",$user,$pass,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
}
catch(PDOException $e){
    exit('Server error');
}