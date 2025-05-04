<!doctype html>
<?php
    function sent_email($email){
        //send email verification email
        /* require 'PHPMailer/src/Exception.php';
        require 'PHPMailer/src/PHPMailer.php';
        require 'PHPMailer/src/SMTP.php';
        require 'connect.php';
        try{
            //configurate for the right email account
            $login;
            $mail=new PHPMailer();
            $mail->isSMTP();
            $mail->Host='smtp.gmail.com';
            $mail->Port=465;
            $mail->SMTPSecure=PHPMAILER::ENCRYPTION_SMTPS;
            $mail->SMTPAuth=true;
            $mail->username='YouWish@gmail.com';
            $mail->Password='YouWish';
            $mail->CharSet='UTF-8';
            $mail->setFrom('no-reply@domain.pl','Clinic');
            $mail->addAddress($email);
            $mail->addReplyTo('Clinic@domein.pl','Biuro obsługi klienta Kear Morhen');
            $mail->isHTML(true);
            $mail->Subject='Email verification- Wojsławice clinic';
            $mail->body="
            <html>
                <head>
                <title>Verify your email</title>
                </head>
                <body>
                <h1>Email verification</h1>
                <p>Finish registering by verifying your email</p>
                <a href=\"http://localhost/clinic/email_ver.php?t=$dec\">Verify email</a>
                <hr>
                <p>Administrator of your personal data is:</p>
                <p>Wojsławice Clinic. Wiejska 4/6/8, 00-902 Wojsławice</p>
                </body>
            </html>
            
            
            
            ";
            $mail->send();
        }
        catch(EXCEPTION $e){
            echo "Error in email delivery: {$mail->Errorinfo}";
        }*/
        header('Location: login.php&new=1');
    }
    if(isset($_POST['name'])){
        session_start();
        $login=htmlspecialchars(trim($_POST['login']));
        $name=htmlspecialchars(trim($_POST['name']));
        $surname=htmlspecialchars(trim($_POST['surname']));
        $password=htmlspecialchars(trim($_POST['password']));
        $password2=htmlspecialchars(trim($_POST['password2']));
        $email=filter_var($_POST['email'],FILTER_SANITIZE_EMAIL);
        $social=htmlspecialchars(trim($_POST['social']));

        if(!ctype_digit($social)||strlen($social)!=11) $error="<p class=error>Invalid social security number</p>";
        else{
            //configured for Polish Pesel, change in case of deployment in a different country
            $checksum=$social[0]*1 + $social[1]*3 + $social[2]*7 + $social[3]*9 + $social[4]*1 + $social[5]*3 + $social[6]*7 + $social[7]*9 + $social[8]*1 + $social[9]*3; 
            $checksum=(10-$checksum%10)%10;
            if($checksum!=$social[10])$error="<p class=error>Invalid social security number</p>";
        }
        if(strlen($name)<2||strlen($name)>50)$error="<p class=error>Invalid name</p>";
        if(strlen($surname)<2||strlen($surname)>50)$error="<p class=error>Invalid surname</p>";
        if(!strlen($password))$error="<p class=error>Invalid password</p>";
        if($password!=$password2) $error="<p class=error>Passwords don't match</p>";
        if(!filter_var($email,FILTER_VALIDATE_EMAIL)) $error="<p class=error>Invalid email</p>";
        if(!isset($error)){
            require_once('connect.php');
            $query=$polaczenie->prepare("SELECT patient_id from patient where patient_log=:log");
            $query->bindValue(':log',$login,PDO::PARAM_STR);
            $query->execute();
            $result=$query->fetch();
            if(!$result) $error="<p class=error>Login already in  use</p>";
            else{
                $bytes = openssl_random_pseudo_bytes(100);
                $dec=htmlspecialchars(base64_encode($bytes));
                $password=password_hash($password,PASSWORD_BCRYPT);
                $query=$polaczenie->prepare("INSERT INTO patient VALUES(NULL,:name,:surname,:social,:log,:pass,:email,'$dec')");
                $query->execute(['name'=>$name,'surname'=>$surname,'social'=>$social,'log'=>$login,'pass'=>$password,'email'=>$email]);
                $_SESSION["mail"]=$email;
                if($query){
                    sent_email($email);
                }
                else $error="<p class=error>Something went wrong, please try again later</p>";
            }
        }
    }if(isset($_GET["t"])){
        session_start();
        sent_email($_SESSION["email"]);
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
<div id="container">
        <header>
            <h1>Sign up</h1>
        </header>
        <main>
            <article>
                <form method="post" action="<?=$_SERVER['PHP_SELF']?>">
                    <label>Name</label>
                    <input type="text" name="name" value="<?= isset($name)? $name:""?>" >
                    <label>Surname</label>
                    <input type="text" name="surname" value="<?= isset($surname)? $surname:""?>" >
                    <label>Login</label>
                    <input type="text" name="login" value="<?= isset($login)? $login:""?>" >
                    <label>Email</label>
                    <input type="email" name="email" value="<?= isset($email)? $email:""?>" >

                    <label>Social security</label>
                    <input type="password" name="social" >
                    <label>Password</label>
                    <input type="password" minlength="8" name="pass">
                    <label>Repeat Password</label>
                    <input type="password"  name="pass2">
                    <br>
                    <input type="submit" value="Dalej!">
                    <?= isset($error) ? $error:''?>
                </form>
            </article>
        </main>

    </div>


</body>