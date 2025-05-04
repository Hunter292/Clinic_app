<!doctype html>
<?php
    if(isset($_POST['login'])){
        session_start();
        $login=htmlspecialchars(trim($_POST['login']));
        $pass=htmlspecialchars(trim($_POST['pass']));
        require('connect.php');
        $query=$polaczenie->prepare("SELECT patient_id,patient_pass,verified from patient where patient_log=:login");
        $query->bindValue(':login',$login,PDO::PARAM_STR);
        $query->execute();
        $user=$query->fetch();
        if($user && password_verify($pass,$user['patient_pass']) && !$user["verified"]){
            $_SESSION['logged']=true;
            $_SESSION['log_id']=$user['patient_id'];
            if(isset($_SESSION['redir'])){
                header('Location: '.$_SESSION['redir']);
                unset($_SESSION['redir']);
                exit();  
            } else{
                header('Location: visits.php');
                exit();
            }
        }else $error="<p class=\"error\">Incorrect login data or unverified email</p>";
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
                <?php if(isset($_GET['new'])){?><h4>Thank you for registering, please verify your email</h4><?php }?>
                
                <?php if(isset($_GET['ver'])){?><h4>Thank you for verifying your email</h4><?php }?>
                <?php if(isset($_GET['err'])){?><h4>Something went wrong, please try again later</h4><?php }?>

                <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Login</label>
                    <input type="text" name="login" value="<?= isset($name)? $name:""?>" >

                    <label>Password</label>
                    <input type="password"  name="pass">
                    <br>
                    <input type="submit" value="Dalej!">
                    <?= isset($error) ? $error:''?>
                </form>
                <h3>Don't have an account? <a href="sign_up.php" >Sign up!</a></h3>
                <?php if(isset($_GET['new'])){?><a href="sign_up.php?t=1">Resend email?<><?php }?>

            </article>
        </main>

    </div>


</body>