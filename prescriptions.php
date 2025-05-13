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
            <h1>Your prescriptions</h1>
        </header>
        <main>
            <article>
                <?php
                    require('connect.php');
                    
                    $query=$polaczenie->query("SELECT worker.name as wname,surname,doctor.specialisation,service.name as sname,date,content FROM prescription join appointment using(app_id) join doctor using(doc_id)
                    join worker using(worker_id) join service using(service_id) where patient_id=\"{$_SESSION["log_id"]}\" order by date desc");
                    if($query){
                        $result=$query->fetchAll();
                        foreach($result as $res){
                            $output="<div class=\"appo\"><div class=flexbox><p>$res[date]</p><p>{$res["specialisation"]}</p><p>{$res["sname"]}</p></div>
                            <p>Doctor {$res["wname"]} {$res["surname"]}</p>";
                            $output.="<div><p>{$res["content"]}</p></div>";
                            $output.="</div>";
                            echo $output;
                        }
                    }
                ?>
            </article>
        </main>

    </div>


</body>