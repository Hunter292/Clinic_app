<?php
    session_start();
    if(!isset($_SESSION['logged'])){
        $_SESSION['redir']=$_SERVER['PHP_SELF'];
        header('Location:login.php');
    }
?>