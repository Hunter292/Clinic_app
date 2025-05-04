<?php
if(!isset($_GET['t'])) header("Location: login.php");
$verify=htmlspecialchars(trim($_GET["t"]));
require "connect.php";
if($verify){
    $query=$polaczenie->prepare("UPDATE patient set verified=0 where verified=:ver");
    $query->bindValue(":ver",$verify,PDO::PARAM_STR);
    $query->execute();
    if($query) header("Location: login.php?ver=1");
    else header("Location: login.php?err=1");
} header("Location login.php");
?>