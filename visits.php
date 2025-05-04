<!doctype html>
<?php
    require('check_log.php');
    require('connect.php');
    if(isset($_GET["r"])){
        $app=htmlspecialchars(trim($_GET["r"]));
        $query=$polaczenie->prepare("SELECT app_id FROM appointment WHERE patient_id={$_SESSION["log_id"]} AND date>='".date("Y-m-d")."' AND app_id=:app");
        $query->bindValue(":app",$app,PDO::PARAM_INT);
        $query->execute();
        $result=$query->fetchAll();
        if($result){
            $query=$polaczenie->query("DELETE FROM appointment WHERE app_id=$app");
            if(!$query) $error="<p class=\"error\">Something went wrong</p>";
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
            <h1>Your appointments</h1>
        </header>
        <main>
            
            
            <article>
                <?= isset($error) ? $error:''?>
                <h1>Upcoming appointment</h1>
                <?php
                    
                    $query=$polaczenie->query("SELECT appointment.app_id as app_id,worker.name as wname,surname,doctor.specialisation,service.name as sname,appointment.time,date,room_number FROM appointment join doctor using(doc_id)
                    join worker using(worker_id) join service using(service_id) left join room using(room_id) where patient_id=".$_SESSION["log_id"].
                    " AND date>='".date("Y-m-d")."'");
                    if($query){
                        $result=$query->fetchAll();
                        foreach($result as $res){
                            $output="<div class=\"appo\"><div class=flexbox><p>$res[date]</p><p>". substr($res["time"],0,8)."</p><p>{$res["sname"]}</p></div>
                            <div class=flexbox><p>Doctor {$res["wname"]} {$res["surname"]}</p><p>{$res["specialisation"]}</p></div>";
                            if($res["room_number"])$output.="<p>room number: {$res["room_number"]}</p>";
                            $output.="<a class=\"mini\" href=\"{$_SERVER["PHP_SELF"]}?r={$res["app_id"]}\" onclick=\"return confirm('Are you sure?')\">Cancel</a>";
                            $output.="</div>";
                            echo $output;
                        }
                    }
                echo "<h1>Past appointments</h1>";
                    $query=$polaczenie->query("SELECT worker.name as wname,surname,doctor.specialisation,service.name as sname,appointment.time,date,recommendations FROM appointment join doctor using(doc_id)
                    join worker using(worker_id) join service using(service_id) where patient_id=".$_SESSION["log_id"].
                    " AND date<\"".date("Y-m-d")."\"");
                    if($query){
                        $result=$query->fetchAll();
                        foreach($result as $res){
                            $output="<div class=\"appo\"><div class=flexbox><p>$res[date]</p><p>". substr($res["time"],0,8)."</p><p>{$res["sname"]}</p></div>
                            <div class=flexbox><p>Doctor {$res["wname"]} {$res["surname"]}</p><p>{$res["specialisation"]}</p></div>";
                            if($res["recommendations"])$output.="<p>{$res["recommendations"]}</p>";
                            $output.="</div>";
                            echo $output;
                        }
                    }
                ?>
            </article>
        </main>
    </div>

</body>