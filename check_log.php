<?php
    session_start();
    if(!isset($_SESSION['logged'])){
        $_SESSION['redir']=$_SERVER['PHP_SELF'];
        header('Location:login.php');
        exit();
    }
    if(!isset($type)){echo "You forgot type!!!!!!";exit(); }
    switch($type){
        case 1: if(!isset($_SESSION['log_id'])) header('Location:login.php'); break;
        case 2: if(!isset($_SESSION['doc_id'])) header('Location:worker_log.php');break;
        case 3: if(!isset($_SESSION['a_id'])) header('Location:worker_log.php');break;
        default: {echo "You forgot type!!!!!!";exit(); }
    }
?>