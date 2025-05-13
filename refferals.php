<!doctype html>
<?php
    $type=1;
    require('check_log.php');
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
<?php include "menu.php" ?>

<div id="container">
        <header>
            <h1>Your refferals</h1>
        </header>
        <main>
            <article>
                <h1>Active refferals</h1>
                <?php
                    require('connect.php');
                    
                    $query=$polaczenie->query("SELECT refferal.refferal_id as refferal_id,worker.name as wname,surname,service.specialisation,service.name as sname,suggested_time FROM refferal join appointment using(app_id) join doctor using(doc_id)
                    join worker using(worker_id) join service on service.service_id=refferal.service_id where patient_id=".$_SESSION["log_id"].
                    " AND spent=0 order by date desc");
                    if($query){
                        $result=$query->fetchAll();
                        foreach($result as $res){
                            $output="<div class=\"appo\"><div class=flexbox><p>Suggested date: $res[suggested_time]</p><p>{$res["specialisation"]}</p><p>{$res["sname"]}</p></div>
                            <p>Doctor {$res["wname"]} {$res["surname"]}</p>";
                            $output.="<a class=\"mini\" href=\"make_ap.php?r={$res["refferal_id"]}\">Reserve</a>";
                            $output.="</div>";
                            echo $output;
                        }
                    }
                echo "<h1>Past refferals</h1>";
                    $query=$polaczenie->query("SELECT worker.name as wname,surname,service.specialisation,service.name as sname,suggested_time FROM refferal join appointment using(app_id) join doctor using(doc_id)
                    join worker using(worker_id) join service on service.service_id=refferal.service_id where patient_id=".$_SESSION["log_id"].
                    " AND spent=1 order by date desc");
                    if($query){
                        $result=$query->fetchAll();
                        foreach($result as $res){
                            $output="<div class=\"appo\"><div class=flexbox><p>Suggested date: $res[suggested_time]</p><p>{$res["specialisation"]}</p><p>{$res["sname"]}</p></div>
                            <p>Doctor {$res["wname"]} {$res["surname"]}</p>";
                            $output.="</div>";
                            echo $output;
                        }
                    }
                ?>
            </article>
        </main>

    </div>


</body>