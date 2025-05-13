<!doctype html>
<?php
    $type=2;
    require('check_log.php');
    require('connect.php');
    if(isset($_GET["t"])){
        $patient=htmlspecialchars(trim($_GET["t"]));
        $query=$polaczenie->prepare("SELECT patient_id FROM appointment WHERE doc_id={$_SESSION["doc_id"]} AND patient_id=:pat");
        $query->bindValue(":pat",$patient,PDO::PARAM_INT);
        $query->execute();
        $result=$query->fetch();
        if(!$result){
           //$error="<p class=\"error\">You can only view your own patients</p>";
           header("Location: doc_visits.php");
           exit();
        }
    }else{
        header("Location: doc_visits.php");
        exit();
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
    <?php include "menu.php" ?>
<div id="container">
        <header>
            <h1>Pacients medical history</h1>
        </header>
        <main>
            
            <article>
                <?= isset($error) ? $error:''?>
                <?php
                    
                    $query=$polaczenie->query("SELECT worker.name as wname,surname,doctor.specialisation,service.name as sname,appointment.time,date,recommendations FROM appointment join doctor using(doc_id)
                    join worker using(worker_id) join service using(service_id) where patient_id=".$patient.
                    " AND date<'".date("Y-m-d")."' order by date desc");
                    $query2=$polaczenie->query("SELECT worker.name as wname,surname,doctor.specialisation,service.name as sname,date,content FROM prescription join appointment using(app_id) join doctor using(doc_id)
                    join worker using(worker_id) join service using(service_id) where patient_id=$patient order by date desc");
                    if($query && $query2){
                        $result=$query->fetchAll();
                        $result2=$query2->fetchAll();
                        $r1=0;$r2=0;
                        //print_r($result2);
                        for($i=0;$i<count($result)+count($result2);$i++){
                            if(($r2>=count($result2)||$result[$r1]["date"]>=$result2[$r2]["date"])&&$r1!=count($result)){
                                $output="<div class=\"appo\"><p>Appointment</p><div class=flexbox><p>{$result[$r1]["date"]}</p><p>". substr($result[$r1]["time"],0,8)."</p><p>{$result[$r1]["sname"]}</p></div>
                                <div class=flexbox><p>Doctor {$result[$r1]["wname"]} {$result[$r1]["surname"]}</p><p>{$result[$r1]["specialisation"]}</p></div>";
                                if($result[$r1]["recommendations"])$output.="<div><p>{$result[$r1]["recommendations"]}</p></div>";
                                $output.="</div>";
                                echo $output;
                                $r1++;
                            }else{
                                $output="<div class=\"appo\"><p>Prescription</p><div class=flexbox><p>{$result2[$r2]["date"]}</p><p>{$result2[$r2]["specialisation"]}</p><p>{$result2[$r2]["sname"]}</p></div>
                                <p>Doctor {$result2[$r2]["wname"]} {$result2[$r2]["surname"]}</p>";
                                $output.="<div><p>{$result2[$r2]["content"]}</p></div>";
                                $output.="</div>";
                                echo $output;
                                $r2++;
                            }
                        }
                    }
                ?>
            </article>
        </main>
    </div>

</body>