<!doctype html>
<?php
    if(isset($_POST['login'])){
        session_start();
        $login=htmlspecialchars(trim($_POST['login']));
        $pass=htmlspecialchars(trim($_POST['pass']));
        if(isset($_POST['role'])){
            $role=htmlspecialchars(trim($_POST['role']));
            require('connect.php');
            if($role=="doctor"){
                $query=$polaczenie->prepare("SELECT doc_id,doc_pass as pass from doctor where doc_log=:login");
            } else $query=$polaczenie->prepare("SELECT admin_id, pass from admin where login=:login"); 
            $query->bindValue(':login',$login,PDO::PARAM_STR);
            $query->execute();
            $user=$query->fetch();
            if($user /*&& password_verify($pass,$user['pass'])*/){
                $_SESSION['logged']=true;
                if($role=="doctor")$_SESSION['doc_id']=$user["doc_id"];
                else $_SESSION['a_id']=$user["admin_id"];
                if(isset($_SESSION['redir'])){
                    header('Location: '.$_SESSION['redir']);
                    unset($_SESSION['redir']);
                    exit();  
                } else{
                    echo"tset";
                    header($role=="doctor"?'Location: doc_visits.php':'Location: admin_main.php');
                    exit();
                }
            }else $error="<p class=\"error\">Incorrect login data</p>";
        }else $error="<p class=\"error\">Incorrect login data</p>";
        $name=$_POST['login'];
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
<div id="container">
        <header>
            <h1>Log in</h1>
        </header>
        <main>
            <article>
                <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Login</label>
                    <input type="text" name="login" value="<?= isset($name)? $name:""?>" >
                    <label>Password</label>
                    <input type="password"  name="pass">
                    <p>Role</p>
                    <input type="radio" name="role" value="doctor" id="doctor"/><label style="display:inline;" for="doctor">Doctor</label>
                    <input type="radio" name="role" value="administrative" id="administrative"/><label style="display:inline;" for="administrative">Administrative</label>
                    <br>
                    <input type="submit" value="Continue!">

                    <?= isset($error) ? $error:''?>
                </form>

            </article>
        </main>

    </div>


</body>