<?php
    $type=2;
    require("check_log.php");
    require("connect.php");
    function validateDate($date, $format = 'Y-m-d'){
        $d = DateTime::createFromFormat($format, $date);
        return $d && $d->format($format) == $date;
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
<body onload="zegar()">
<?php include("menu.php")?>
<div id="container">
        <header>
            <h1>Schedule</h1>
        </header>
        <main>
            <article>
                <section>
                    <?php
                        if(isset($_POST["date"])){
                            $date=htmlspecialchars(trim($_POST["date"]));
                            if(ValidateDate($date)){
                                echo"<table border=\"1\" class=\"schedule\" cellpadding=\"10\" cellspacing=\"0\">";
                                echo"<thead><tr><th colspan=\"8\">Weekly schedule</th></tr><tr><th>Hour</th>
                                <th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Sunday</th></tr></thead><tbody>";
                                $query=$polaczenie->query("SELECT weekday, clock_in, clock_out, lunch_break FROM doc_schedule where doc_id={$_SESSION["doc_id"]} order by weekday");
                                $query2=$polaczenie->query("SELECT weekday, clock_in, clock_out, lunch_break, min(firing_date) FROM upcoming_doc_sche where firing_date<=$date group by weekday order by weekday ");
                                $result1=$query->fetchAll();
                                $result2=$query->fetchAll();
                                $j=0;
                                $hours=array();
                                for($i=0;$i<24;$i++){
                                    $hours[$i]="<tr><th>".(8+($i-$i%2)/2).($i%2?'-30':'-00')."</th>";
                                }
                                foreach($result1 as $res){
                                    if($j<count($result2)&&$res["weekday"]==$result2[$j]["weekday"]){
                                        $inn=explode(':',$result2[$j]["clock_in"]);
                                        $outt=explode(':',$result2[$j]["clock_out"]);
                                        $breakk=explode(':',$result2[$j]["lunch_break"]);
                                        if($j+1!=count($result2))$j++;
                                    }else{
                                        $inn=explode(':',$res["clock_in"]);
                                        $outt=explode(':',$res["clock_out"]);
                                        $breakk=explode(':',$res["lunch_break"]);
                                    }
                                    $in=date('H-i',mktime($inn[0],$inn[1]));
                                    $out=date('H-i',mktime($outt[0],$outt[1]));
                                    $break=date('H-i',mktime($breakk[0],$breakk[1]));

                                    for($i=0;$i<24;$i++){
                                        $hour=date('H-i',mktime(8+($i-$i%2)/2,$i%2*30));
                                       if(($in<=$hour)&&($out>$hour)&&($break!=$hour)){
                                        $do_work="schedule_on";
                                       }else $do_work="";
                                        $hours[$i].="<th class=\"$do_work\"></th>";
                                    }
                                }
                                for($i=0;$i<24;$i++){
                                    $hours[$i].="</tr>";
                                    echo $hours[$i];
                                }

                                echo"</tbody></table>";
                            }
                        }
                    ?>
                </section>
                <section>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                        <label>Select week</label>
                        <input type="date" name="date">
                        <br>
                        <input type="submit" value="Continue!">

                        <?= isset($error) ? $error:''?>
                    </form>
                </section>
            </article>
        </main>

    </div>


</body>