<!doctype html>
<?php
    $type=2;
    require('check_log.php');
    require('connect.php');
    function validateDate($date, $format = 'Y-m-d'){
        $d = DateTime::createFromFormat($format, $date);
        return $d && $d->format($format) == $date;
    }
    //check if valid entry into the script
    if(isset($_GET["t"])){
        $app=htmlspecialchars(trim($_GET["t"]));
        $query=$polaczenie->prepare("SELECT app_id FROM appointment WHERE doc_id={$_SESSION["doc_id"]} AND app_id=:app");
        $query->bindValue(":app",$app,PDO::PARAM_INT);
        $query->execute();
        $result=$query->fetch();
        $_SESSION["app"]=$app;
        if(!$result){
           //$error="<p class=\"error\">You can only view your own patients</p>";
           header("Location: doc_visits.php");
           exit();
        }
    }else if(!isset($_SESSION["app"])){ 
        header("Location: doc_visits.php");
        exit();
    } else $app=$_SESSION["app"];
    //update recommendations
    if(isset($_POST["recom"])){
        $recom=htmlspecialchars(trim($_POST["recom"]));
        if($recom){
            $query=$polaczenie->prepare("UPDATE appointment set recommendations=:rec where app_id=$app");
            $query->bindValue(":rec",$recom, PDO::PARAM_STR);
            $query->execute();
            if(!$query) $error="<p class=\"error\">Something went wrong</p>";
        }
    }
    //update/insert prescription
    if(isset($_POST["pres"])){
        $pres=htmlspecialchars(trim($_POST["pres"]));
        if($pres){
            if(!isset($_SESSION["pres_none"])){
                $query=$polaczenie->prepare("UPDATE prescription set content=:pre where app_id=$app");
            }else{
                unset($_SESSION["pres_none"]);
                $query=$polaczenie->prepare("INSERT INTO prescription values(NULL,$app,:pre)");
            }
            $query->bindValue(":pre",$pres, PDO::PARAM_STR);
            $query->execute();
            if(!$query) $error="<p class=\"error\">Something went wrong</p>";
        }
    }
    // remove refferal
    if(isset($_GET["r"])){
        $ref=htmlspecialchars(trim($_GET["r"]));
        $query=$polaczenie->prepare("SELECT refferal.refferal_id from refferal join appointment using(app_id) where refferal.refferal_id=:ref AND doc_id={$_SESSION["doc_id"]}");
        $query->bindValue(":ref",$ref,PDO::PARAM_STR);
        $query->execute();
        if($query){
            $query=$polaczenie->query("DELETE FROM refferal WHERE refferal_id=$ref");
            if(!$query) $error="<p class=\"error\">Something went wrong</p>";
        }
    }
    //insert refferal
    if(isset($_POST["date"])){
        $date=htmlspecialchars(trim($_POST["date"]));
        $service=htmlspecialchars(trim($_POST["service"]));
        $query=$polaczenie->prepare("SELECT service_id FROM service where service_id=:ser AND available=true"); 
        $query->bindValue(':ser',$service,PDO::PARAM_INT);
        $query->execute();
        $result=$query->fetch();
        if(validateDate($date)&& $service && $result){
            $query=$polaczenie->query("INSERT INTO refferal VALUES(NULL,$app,$service,'$date',0)");
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
    <?php include "menu.php" ?>
    <div id="container">
        <header>
            <h1>Visit detail</h1>
        </header>
        <main>
            <article>
                <?= isset($error) ? $error:''?>
                <?php
                    $query=$polaczenie->query("SELECT appointment.patient_id,patient.name as wname,surname,service.name as sname,appointment.time,date,room_number,recommendations FROM appointment join patient using(patient_id)
                    join service using(service_id) left join room using(room_id) where app_id=$app");
                    if($query){
                        $res=$query->fetch();
                        $output="<div class=\"appo\"><div class=flexbox><p>$res[date]</p><p>". substr($res["time"],0,8)."</p><p>{$res["sname"]}</p></div>
                        <div><a class=\"mini\" href=\"patient_view.php?t={$res["patient_id"]}\">{$res["wname"]} {$res["surname"]}</a></div>";
                        if($res["room_number"])$output.="<p>room number: {$res["room_number"]}</p>";
                        $output.="<div><p>{$res["recommendations"]}</p></div>";
                        $output.="</div>";
                        echo $output;
                    }
                    
                ?>
                <section>
                    <h3>Recommendations</h3>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <textarea name="recom"><?=$res["recommendations"]?></textarea>
                    <br>
                    <input type="submit" value="Continue!">

                    </form>
                </section>
                <section>
                    <?php
                        $query=$polaczenie->query("SELECT content FROM prescription where app_id=$app");
                        $result=$query->fetch();
                        if(!$result){$_SESSION["pres_none"]=1;echo"test";};
                    ?>
                    <h3>Prescriptions</h3>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <textarea name="pres"><?=isset($result["content"])?$result["content"]:""?></textarea>
                    <br>
                    <input type="submit" value="Continue!">

                    </form>
                </section>
                <section>
                    <?php
                        $query=$polaczenie->query("SELECT content FROM prescription where app_id=$app");
                        $result=$query->fetch();
                    ?>
                    <h3>Refferals</h3>
                    <?php
                        $query=$polaczenie->query("SELECT refferal_id, suggested_time, name,specialisation FROM refferal join service using(service_id) where app_id=$app");
                        if($query){
                            $result=$query->fetchAll();
                            foreach($result as $res){
                                $output="<div class=\"appo\"><div class=flexbox><p>{$res["suggested_time"]}</p><p>{$res["name"]}</p><p>{$res["specialisation"]}</p></div>";
                                $output.="<a class=\"mini\" href=\"{$_SERVER["PHP_SELF"]}?r={$res["refferal_id"]}\" onclick=\"return confirm('Are you sure?')\">Remove</a>";
                                $output.="</div>";
                                echo $output;
                            }
                        }
                    ?>
                    <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Suggested Date</label>
                    <input type="date" name="date" min="<?= date('Y-m-d',mktime(0,0,0,date("m"),date("d")+1,date("Y")))?>"/>
                    <label>Service</label>
                    <select name="service">
                        <?php
                            $query=$polaczenie->query("SELECT name, service_id FROM service where available=1");
                            $result=$query->fetchAll();
                            foreach($result as $res){
                                echo"<option value=\"{$res["service_id"]}\">{$res["name"]}</option>";
                            }
                        ?>
                    </select>
                    <br>
                    <input type="submit" value="Continue!">

                    </form>
                </section>
            </article>
        </main>
    </div>
</body>