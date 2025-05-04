<!doctype html>
<?php
    require('check_log.php');
    if(isset($_GET["t"])&&isset($_SESSION["doctor"])){
        require 'connect.php';
        $time=htmlspecialchars(trim($_GET['t']));
        $service=$_SESSION["service"];
        $doctor=$_SESSION["doctor"];
        $date=$_SESSION["date"];
        //verify timeslot
        $query=$polaczenie->query("SELECT `timeslots_for_app`('$doctor','$date','$service') AS `timeslots_for_app`; ");
        $result=$query->fetch();
        if(strpos($result[0],$time)===FALSE){
            unset($_SESSION["doctor"]);
        }
        else{
            $query=$polaczenie->query("INSERT INTO appointment values(NULL,'{$_SESSION['log_id']}','$doctor','$service',NULL,NULL,'$date','$time',NULL)");
            if($query){
                $success=true;
                if(isset($_SESSION["ref"])) $query=$polaczenie->query("UPDATE refferal set spent=1 where refferal_id={$_SESSION["ref"]}");
                unset($_SESSION["ref"]);
            }
            else $error='<p class=error>An error has accured</p>';
        }
        unset($_SESSION["service"]);
        unset($_SESSION["doctor"]);
        unset($_SESSION["date"]);

    }
    function get_doc($service,$date){
        global $polaczenie;
        //verify service
        if(!$_SESSION["ref"])$query=$polaczenie->prepare("SELECT service_id FROM service where service_id=:ser AND available=true AND referral=FALSE"); 
        else $query=$polaczenie->prepare("SELECT refferal_id FROM  refferal where refferal_id={$_SESSION["ref"]} AND service_id=:ser");
        echo"SELECT refferal_id FROM  refferal where refferal_id={$_SESSION["ref"]} AND service_id=$service";
        $query->bindValue(':ser',$service,PDO::PARAM_INT);
        $query->execute();
        $result=$query->fetchall();
        if($date<=date('Y-m-d')|| !$service|| !$result || $date>date('Y-m-d',mktime(0,0,0,date("m"),date("d")+14,date("Y")))) header("Location: {$_SERVER['PHP_SELF']}");

        $_SESSION["service"]=$service;
        $_SESSION["date"]=$date;
        $query=$polaczenie->query("SELECT doc_id,name,surname FROM doctor join worker using(worker_id) where specialisation=(SELECT specialisation from service where service_id=$service)
        AND doc_id not in(SELECT doc_id from doc_leave where begin_date<='$date' AND end_date>='$date' AND approved=1) AND doc_id in(SELECT doc_id FROM doc_schedule where weekday=DAYNAME('$date'))");
        $result=$query->fetchall();
        foreach($result as $res){
            echo "<option value=\"{$res["doc_id"]}\">{$res["name"]} {$res["surname"]}</option>";
        }
        
    }
?>
<head>
	<meta charset="utf-8">
	<meta name="autor" content="Kacper Ćwiek">
	<meta name="keyword" content="Clinic, healthcare, Wojsławice">
	<meta name="description" content="">
	<title> Clinic </title>
    <link rel="stylesheet" href="style.css">
    <script type="text/javascript" src="script.js"></script>

    <!--[if lt IE 9]>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv.min.js"></script>
    <![endif]-->
</head>
<body>
<?php include "menu.html" ?>

<div id="container">
        <header>
            <h1>Making an appointment</h1>
            <?=isset($success)?"<h3>Appointment successfully reserved</h3>":"" ?>
        </header>
        <main>
            <article>
                <?php if(!isset($_POST["service"])&&!isset($_POST["doctor"])&&!isset($_POST["date"])){ ?>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Date</label>
                    <input type="date" name="date" required max="<?= date('Y-m-d',mktime(0,0,0,date("m"),date("d")+14,date("Y")))?>" min="<?= date('Y-m-d',mktime(0,0,0,date("m"),date("d")+1,date("Y")))?>">
                    <label>Service</label>
                    <select name="service">
                        <?php
                            require "connect.php";
                            if(isset($_SESSION["doctor"]))unset($_SESSION["doctor"]);
                            if(isset($_SESSION["ref"]))unset($_SESSION["ref"]);
                            if(!isset($_GET['r'])){ 
                                $query=$polaczenie->query("SELECT name,service_id from service where available=true and referral=false");
                                $result=$query->fetchall();
                                foreach($result as $res){
                                    echo "<option value=\"{$res["service_id"]}\">{$res["name"]}</option>";
                                }
                            }else{
                                $ref=htmlspecialchars(trim($_GET['r']));
                                $query=$polaczenie->prepare("SELECT refferal.refferal_id,service.service_id as id,name FROM refferal join appointment using(app_id) join service on refferal.service_id=service.service_id 
                                where patient_id={$_SESSION["log_id"]} AND spent=0 AND available=1 AND refferal.refferal_id=:ref");
                                $query->bindValue(":ref",$ref,PDO::PARAM_INT);
                                $query->execute();
                                $result=$query->fetchall();
                                if(!$result) $error="<p class=\"error\">Refferal is invalid or the service is no longer available</p>";
                                else{
                                    $_SESSION["ref"]=$ref;
                                    echo "<option value=\"{$result[0]["id"]}\">{$result[0]["name"]}</option>";
                                }
                            }
                        ?>
                    </select>
                    <br>
                    <input type="submit" value="Continue!">
                    </form>
                    <br>
                    <?= !isset($_GET["r"])? "<div><a href=\"refferals.php\">Have a refferal?</a></div>": ""?>
                <?php ;}if(isset($_POST["service"])){ ?>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Doctor</label>
                    <select name="doctor">
                        <?php
                            require "connect.php";
                            $service=htmlspecialchars(trim($_POST["service"]));
                            $date=htmlspecialchars(trim($_POST["date"]));
                            get_doc($service,$date);
                        ?>
                    </select>
                    <br>
                    <input type="submit" value="Continue!">
                    </form>
                <?php ;}if(isset($_POST["doctor"])||(isset($_SESSION["doctor"])&&isset($_POST["date"]))){ 
                        require "connect.php";
                    if(isset($_POST["doctor"])){
                        $doctor=htmlspecialchars(trim($_POST["doctor"]));
                        $date=$_SESSION["date"];
                    }
                    else{
                        $date=htmlspecialchars(trim($_POST["date"]));
                        $doctor=$_SESSION["doctor"];
                    }
                    $service=$_SESSION["service"];
                    //verify doctor
                    $query=$polaczenie->prepare("SELECT doc_id from doctor where doc_id=:doc AND specialisation=(SELECT specialisation FROM service where service_id=$service)
                    AND doc_id not in(SELECT doc_id from doc_leave where begin_date<='$date' AND end_date>='$date' AND approved=1)");
                    $query->bindValue(':doc',$doctor,PDO::PARAM_INT);
                    $query->execute();
                    $result=$query->fetchall();
                    if($date<=date('Y-m-d')||!$result)header("Location: {$_SERVER['PHP_SELF']}");

                    $_SESSION['doctor']=$doctor;
                    $_SESSION['date']=$date;
                    $query=$polaczenie->query("SELECT `timeslots_for_app`('$doctor','$date','$service') AS `timeslots_for_app`; ");
                    $result=$query->fetch();
                    if(!$result[0]) echo"<h3>No available visits</h3>";
                    else{
                    ?>
                    <table class="zestawienie" border="1" cellpadding="10" cellspacing="0">
                    <thead>
                        <tr><th colspan="6">Available hours</th></tr>
                    </thead>
                    <tbody>
                        <?php
                            $res=explode(',',$result[0]);
                            $i=0;
                            foreach($res as $re){
                                if($i==0)echo"<tr>";
                                echo"<th>$re</th><th><a class=\"mini\" href=\"{$_SERVER['PHP_SELF']}?t=$re\">Select</a></th>";
                                $i++;
                                if($i==3){
                                    echo "</tr>";
                                    $i=0;
                                }
                            }
                        ?>
                    </tbody>
                    </table>
                        <?php } ?>
                    <div style="margin-bottom: 150px;"></div>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Change doctor</label>
                    <select name="doctor">
                        <?php get_doc($_SESSION["service"],$date);?>
                    </select>
                    <br>
                    <input type="submit" value="Continue!">
                    </form>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Change date</label>
                    <input type="date" name="date" max="<?= date('Y-m-d',mktime(0,0,0,date("m"),date("d")+14,date("Y")))?>" min="<?= date('Y-m-d',mktime(0,0,0,date("m"),date("d")+1,date("Y")))?>"value="<?=isset($_SESSION["date"])?$_SESSION["date"]:"" ?>">
                    <br>
                    <input type="submit" value="Continue!">
                    </form>
                <?php }?>
                    <?= isset($error) ? $error:''?>
            </article>
        </main>

    </div>


</body>