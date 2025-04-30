-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 30, 2025 at 01:53 PM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `clinic`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `fill_missing_pres` (IN `day` DATE)   BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE id,p_r,p_p INT;
DECLARE content TEXT;
DECLARE cur CURSOR FOR SELECT appointment.app_id,appointment.recommendations FROM appointment WHERE appointment.date=day AND appointment.recommendations NOT IN("") AND appointment.app_id NOT IN(SELECT app_id FROM prescription);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
OPEN cur;
read_loop: LOOP
	FETCH cur INTO id,content;
    IF done THEN
      LEAVE read_loop;
    END IF;
	SET p_p=LOCATE('Prescription',content);
    IF p_p=0 THEN SET p_p=LOCATE('prescription',content); END IF;
	IF(p_p>0) THEN
    	SET p_r=LOCATE('Recommendations',content);
        IF p_r=0 THEN SET p_r=LOCATE('recommendations',content); END IF;
        IF p_r>p_p THEN SET content=SUBSTRING(content,p_p+12,p_r-p_p-12);
        ELSE SET content=SUBSTRING(content,p_p+12);
        END IF;
        INSERT INTO prescription VALUES (0,id,content);
    END IF;
END LOOP;
CLOSE cur;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_worker` (IN `name` VARCHAR(50) CHARSET utf8mb4, IN `surname` VARCHAR(50) CHARSET utf8mb4, IN `position` VARCHAR(100) CHARSET utf8mb4, IN `phone` VARCHAR(13) CHARSET utf8mb4, IN `em` TINYTEXT CHARSET utf8mb4, IN `specialisation` VARCHAR(100) CHARSET utf8mb4, IN `ad_level` INT)   BEGIN
DECLARE w_id INT;
DECLARE ad_p,abort BOOLEAN DEFAULT FALSE;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        -- SET abort=TRUE;
    END;
START TRANSACTION;
    INSERT INTO worker VALUES(NULL,name,surname,position,phone,em);
    IF(position="doctor") THEN
         SELECT worker_id INTO w_id FROM worker where worker.email=em AND worker.phone_number=phone order by worker_id desc LIMIT 1;
        INSERT INTO doctor VALUES(1,w_id,specialisation,em,SHA2(CONCAT(phone," ",em),256));
    END IF;
    IF ad_level>0 THEN
        -- SELECT worker_id INTO w_id FROM worker where worker.email=em AND worker.phone_number=phone order by worker_id desc LIMIT 1;
        IF ad_level=2 THEN SET ad_p=TRUE;
        ELSE SET ad_p=FALSE;
        END IF;
        INSERT INTO admin VALUES(NULL,w_id,em,SHA2(CONCAT(phone," ",em),256),ad_p);
    END IF;
IF !abort THEN COMMIT; END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_app_by_id` (IN `list_id` TEXT CHARSET utf8mb4)   BEGIN
IF RIGHT(list_id,1)=',' THEN
	SET list_id=LEFT(list_id,CHAR_LENGTH(list_id)-1);
END IF;
DELETE FROM appointment WHERE appointment.app_id IN(list_id);
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `doctor_for_service` (`service_i` TINYTEXT CHARSET utf8mb4) RETURNS TEXT CHARSET utf8mb4 DETERMINISTIC BEGIN
DECLARE done BOOLEAN DEFAULT FALSE;
DECLARE a,b TINYTEXT;
DECLARE output TEXT DEFAULT "";
DECLARE c INTEGER;
DECLARE cur CURSOR FOR SELECT name,surname,doc_id FROM doctor JOIN worker USING(worker_id) WHERE specialisation=(SELECT specialisation FROM service WHERE service_id=service_i);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE=TRUE;
OPEN cur;
LOOP1: LOOP
	FETCH cur INTO a,b,c;
    IF done THEN LEAVE LOOP1; END IF;
    SET output=CONCAT(output,a,' ',b,',',c,',');
END LOOP;
CLOSE cur;
RETURN output;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `doc_leave_count` (`doc_idd` INT) RETURNS INT(11) DETERMINISTIC BEGIN
DECLARE a int;
SELECT count(datediff(doc_leave.end_date,doc_leave.begin_date)+1)INTO a FROM doc_leave where doc_id=doc_idd and doc_leave.approved=1 and YEAR(begin_date)=YEAR(curdate());
return a;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `overlapping_app` () RETURNS TEXT CHARSET utf8mb4 DETERMINISTIC BEGIN
DECLARE done INT DEFAULT FALSE;
DECLARE app,doc,prev_d INT DEFAULT 0;
DECLARE ser_t, app_t,prev_s,prev_a TIME;
DECLARE app_list TEXT DEFAULT "";
DECLARE cur CURSOR FOR SELECT app_id, service.time, appointment.time,doc_id FROM appointment JOIN service USING(service_id) WHERE appointment.date>=CURRENT_DATE() ORDER BY doc_id, appointment.date, appointment.time;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
OPEN cur;
FETCH cur INTO app,ser_t,app_t,doc;
SET prev_s=ser_t;
SET prev_a=app_t;
SET prev_d=doc;
read_loop: LOOP
	FETCH cur INTO app,ser_t,app_t,doc;
	IF done THEN
      LEAVE read_loop;
    END IF;
    IF prev_s+prev_a>app_t&&prev_d=doc THEN
    	SET app_list= CONCAT_WS(', ',app,app_list);
    ELSE
    	SET prev_s=ser_t;
        SET prev_a=app_t;
    END IF;
END LOOP;
CLOSE cur;
RETURN app_list;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `replacement_doc` (`a_date` DATE, `service_i` INT) RETURNS INT(11)  BEGIN
DECLARE done BOOLEAN DEFAULT FALSE;
DECLARE time,sum,rem,max time DEFAULT "00:00:00";
DECLARE id,idmax INTEGER DEFAULT 0;
DECLARE cur1 CURSOR FOR SELECT doc_id,SUBTIME(clock_out,clock_in) FROM doc_schedule join doctor using(doc_id) WHERE specialisation=(SELECT specialisation FROM service WHERE service_id=service_i) AND dayname(a_date)=weekday AND
doc_id NOT IN(SELECT doc_id FROM doc_leave WHERE begin_date<=a_date AND end_date>=a_date AND approved=1);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE=TRUE;
OPEN cur1;
LOOP1: LOOP
    FETCH cur1 INTO id,time;
    IF done THEN LEAVE LOOP1; END IF;
    SELECT SEC_TO_TIME(SUM(TIME_TO_SEC(service.time))) INTO sum FROM appointment join service using(service_id) WHERE date=a_date AND doc_id=id;
    IF sum>0 THEN SET rem=SUBTIME(time,sum); else SET rem=time; END IF;
  IF(rem>max) THEN 
    	SET max=rem;
        SET idmax=id;
    END IF;
END LOOP;
CLOSE cur1;
RETURN idmax;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `service_increase` () RETURNS TEXT CHARSET utf8mb4  BEGIN
DECLARE count,ser,sum int;
DECLARE per,past_per,max FLOAT DEFAULT 0.0;
DECLARE output text DEFAULT "";
DECLARE DONE INT DEFAULT FALSE;
DECLARE cur CURSOR FOR SELECT service_id,count(service_id) FROM appointment WHERE MONTH(date)=MONTH(curdate()) AND YEAR(date)=YEAR(curdate()) GROUP BY service_id;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE=TRUE;
SELECT count(app_id) INTO sum FROM appointment WHERE MONTH(date)=MONTH(curdate()) AND YEAR(date)=YEAR(curdate());
OPEN cur;
LOOP1: LOOP
	FETCH cur INTO ser,count;
    IF DONE THEN LEAVE LOOP1; END IF;
	SET per=count/sum*100.0;
    SELECT percentage INTO past_per FROM view_mat_month_report WHERE service_id=ser;
    IF past_per>0 AND per>past_per THEN
    	IF per-past_per>max THEN
        	SET output=ser;
            SET max=per-past_per;
        ELSE IF abs(per-past_per-max)<0.1 THEN SET output=CONCAT(output,",",ser);
        	END IF;
        END IF;  
    END IF;
END LOOP;
CLOSE cur;
RETURN output;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `timeslots_for_app` (`id_doc` INT, `app_date` DATE, `service_i` TINYTEXT CHARSET utf8mb4) RETURNS TEXT CHARSET utf8mb4  BEGIN
DECLARE output TEXT DEFAULT "";
DECLARE clock,start_s,finish,break,duration TIME;
DECLARE done boolean default FALSE;
DECLARE cur CURSOR FOR SELECT appointment.time,service.time FROM appointment join service USING(service_id) WHERE doc_id=id_doc AND appointment.date=app_date;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=TRUE;
SELECT doc_schedule.clock_in,clock_out,lunch_break INTO start_s,finish,break FROM doc_schedule WHERE 
doc_id=id_doc AND doc_schedule.weekday=DAYNAME(app_date);
SELECT service.time INTO duration FROM service where service_id=service_i;

SET output=CONCAT(output,start_s);
SET start_s=ADDTIME(start_s,001500);
SET finish=SUBTIME(finish,duration);

WHILE start_s<=finish DO
	IF ADDTIME(start_s,duration)<=break OR start_s>=ADDTIME(break,003000) THEN
		SET output=CONCAT(output,',',start_s);
    END IF;
    SET start_s=ADDTIME(start_s,001500);
END WHILE;
OPEN cur;
read_loop: LOOP
	FETCH cur INTO clock,break;
    IF DONE THEN LEAVE read_loop; END IF;
    SET start_s=clock;
    SET finish=ADDTIME(start_s,break);
    WHILE start_s<finish DO 
    	SET output=REPLACE(output,start_s,"");
        SET start_s=ADDTIME(start_s,001500);
    END WHILE;
    SET start_s=SUBTIME(clock,001500);
    SET finish=SUBTIME(clock,duration);
    WHILE start_s>finish DO 
    	SET output=REPLACE(output,start_s,"");
        SET start_s=SUBTIME(start_s,001500);
    END WHILE;
END LOOP;
SET output=REPLACE(output,",,,",",");
SET output=REPLACE(output,",,",",");
SET output=REPLACE(output,":00,",",");
RETURN SUBSTRING(output,1,CHAR_LENGTH(output)-3);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL,
  `worker_id` int(11) NOT NULL,
  `login` varchar(50) NOT NULL,
  `pass` tinytext NOT NULL,
  `full_privileges` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`admin_id`, `worker_id`, `login`, `pass`, `full_privileges`) VALUES
(1, 2, '222', '1cd5a4645617625896431322585304b8290ba61bd67a5fe8b4ac9e58b27f69dc', 1),
(2, 7, 'no_email', 'bb934aafd503159e9cafbe60a35c3ddb9f4f956b1738e98ec1bd699f62cb32fd', 1),
(3, 13, 'adad', 'f979c0cfb002c36a7061af08434a94c8fa5e762db1ef83f69bd31587423770af', 1);

-- --------------------------------------------------------

--
-- Table structure for table `appointment`
--

CREATE TABLE `appointment` (
  `app_id` int(11) NOT NULL,
  `patient_id` int(11) NOT NULL,
  `doc_id` int(11) DEFAULT NULL,
  `service_id` int(11) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `refferal_id` int(11) DEFAULT NULL,
  `date` date NOT NULL,
  `time` time(5) NOT NULL,
  `recommendations` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `appointment`
--

INSERT INTO `appointment` (`app_id`, `patient_id`, `doc_id`, `service_id`, `room_id`, `refferal_id`, `date`, `time`, `recommendations`) VALUES
(3, 1, 1, 1, 1, NULL, '2025-12-29', '12:00:00.00000', 'Prescription: amphetamine\nrecommendations: test2'),
(5, 1, 2, 1, 1, NULL, '2024-12-30', '12:15:00.00000', 'Recommendations: test\nPrescription: methamphetamine'),
(6, 1, 1, 1, 1, NULL, '2024-12-29', '09:00:00.00000', NULL),
(7, 2, 1, 2, 2, NULL, '2025-02-12', '14:00:00.00000', 'Prescription: eye drops\nRecommendation: Follow-up in 2 weeks'),
(8, 3, 3, 2, 3, NULL, '2025-02-12', '10:30:00.00000', 'Prescription: iron supplements\nRecommendation: Drink more water'),
(10, 2, 3, 4, 1, NULL, '2024-12-29', '13:00:00.00000', NULL);

--
-- Triggers `appointment`
--
DELIMITER $$
CREATE TRIGGER `delete_app` BEFORE DELETE ON `appointment` FOR EACH ROW BEGIN
IF OLD.refferal_id AND OLD.date>=curdate() THEN
UPDATE refferal SET spent=0 where refferal_id=OLD.refferal_id;
END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `insert_app` BEFORE INSERT ON `appointment` FOR EACH ROW BEGIN
DECLARE a int default 0;
DECLARE t time;
DECLARE b,c text;
SELECT specialisation INTO b FROM service where service_id=NEW.service_id;
SELECT specialisation INTO c FROM doctor where doc_id=NEW.doc_id;
SELECT time into t from service where service.service_id=NEW.service_id;
SELECT appointment.app_id INTO a FROM appointment join service using(service_id) where date=NEW.date and doc_id=NEW.doc_id and ((NEW.time>=appointment.time and NEW.time<appointment.time+service.time)or (appointment.time>NEW.time and appointment.time<NEW.time+t)) LIMIT 1;
IF a THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Attempt to insert appointment at incorrect time"; END IF;
IF b<>c THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Attempt to insert appointment with wrong specialisation doctor"; END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `doctor`
--

CREATE TABLE `doctor` (
  `doc_id` int(11) NOT NULL,
  `worker_id` int(11) NOT NULL,
  `specialisation` varchar(100) NOT NULL,
  `doc_log` varchar(50) NOT NULL,
  `doc_pass` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `doctor`
--

INSERT INTO `doctor` (`doc_id`, `worker_id`, `specialisation`, `doc_log`, `doc_pass`) VALUES
(1, 1, 'apothecary', 'test', 'test'),
(2, 2, 'optometrist', 'test', 'test'),
(3, 3, 'apothecary', '333', 'a1267e3144d933b13b3915198fcbc3e8a1c7cb83020d205705d98cbeabd2da3e'),
(4, 7, 'optometrist', 'no_email', 'bb934aafd503159e9cafbe60a35c3ddb9f4f956b1738e98ec1bd699f62cb32fd'),
(5, 8, 'apothecary', 'sarahc', 'sarahpass'),
(6, 9, 'cardiologist', 'johndoe', 'johnpass'),
(7, 13, 'add', 'adad', 'f979c0cfb002c36a7061af08434a94c8fa5e762db1ef83f69bd31587423770af');

--
-- Triggers `doctor`
--
DELIMITER $$
CREATE TRIGGER `delete_doctor` BEFORE DELETE ON `doctor` FOR EACH ROW BEGIN
DELETE FROM appointment WHERE doc_id=OLD.doc_id AND appointment.date>=CURRENT_DATE();
Update appointment SET appointment.doc_id=0 where doc_id=OLD.doc_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `doc_leave`
--

CREATE TABLE `doc_leave` (
  `leave_id` int(11) NOT NULL,
  `doc_id` int(11) NOT NULL,
  `begin_date` date NOT NULL,
  `end_date` date NOT NULL,
  `approved` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `doc_leave`
--

INSERT INTO `doc_leave` (`leave_id`, `doc_id`, `begin_date`, `end_date`, `approved`) VALUES
(1, 5, '2024-02-14', '2025-02-18', 1),
(2, 6, '2025-02-20', '2025-02-22', 0);

-- --------------------------------------------------------

--
-- Table structure for table `doc_schedule`
--

CREATE TABLE `doc_schedule` (
  `schedule_id` int(11) NOT NULL,
  `doc_id` int(11) NOT NULL,
  `weekday` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `clock_in` time NOT NULL,
  `clock_out` time NOT NULL,
  `lunch_break` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `doc_schedule`
--

INSERT INTO `doc_schedule` (`schedule_id`, `doc_id`, `weekday`, `clock_in`, `clock_out`, `lunch_break`) VALUES
(1, 1, 'Sunday', '08:00:00', '16:00:00', '13:00:00'),
(2, 5, 'Sunday', '08:00:00', '17:00:00', '13:00:00'),
(3, 6, 'Tuesday', '08:00:00', '16:00:00', '12:00:00'),
(4, 3, 'Sunday', '08:00:00', '16:00:00', '13:00:00'),
(5, 1, 'Wednesday', '07:00:00', '15:00:00', '12:00:00');

--
-- Triggers `doc_schedule`
--
DELIMITER $$
CREATE TRIGGER `insert_doc_schedule` BEFORE INSERT ON `doc_schedule` FOR EACH ROW BEGIN
DECLARE a INT DEFAULT 0;
SELECT doc_schedule.schedule_id INTO a FROM doc_schedule WHERE doc_id=NEW.doc_id AND weekday=NEW.weekday;
IF a>0 THEN DELETE FROM doc_schedule WHERE doc_id=NEW.doc_id AND weekday=NEW.weekday;
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `patient`
--

CREATE TABLE `patient` (
  `patient_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `surname` varchar(50) NOT NULL,
  `sec_soc` int(11) NOT NULL,
  `patient_log` varchar(50) NOT NULL,
  `patient_pass` tinytext NOT NULL,
  `patient_email` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `patient`
--

INSERT INTO `patient` (`patient_id`, `name`, `surname`, `sec_soc`, `patient_log`, `patient_pass`, `patient_email`) VALUES
(1, 'adam', 'test', 1112223331, 'lal', 'lal', 'lal'),
(2, 'Jane', 'Doe', 2147483647, 'jane_doe', 'password123', 'jane.doe@email.com'),
(3, 'Max', 'Mustermann', 1234567890, 'max_mustermann', 'password456', 'max.mustermann@email.com');

-- --------------------------------------------------------

--
-- Table structure for table `prescription`
--

CREATE TABLE `prescription` (
  `pres_id` int(11) NOT NULL,
  `app_id` int(11) NOT NULL,
  `content` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `prescription`
--

INSERT INTO `prescription` (`pres_id`, `app_id`, `content`) VALUES
(2, 3, ': amphetamine\n'),
(3, 7, ': eye drops\n'),
(4, 8, ': iron supplements\n');

-- --------------------------------------------------------

--
-- Table structure for table `refferal`
--

CREATE TABLE `refferal` (
  `refferal_id` int(11) NOT NULL,
  `app_id` int(11) NOT NULL,
  `service_id` int(11) NOT NULL,
  `suggested_time` date NOT NULL,
  `spent` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `refferal`
--

INSERT INTO `refferal` (`refferal_id`, `app_id`, `service_id`, `suggested_time`, `spent`) VALUES
(1, 7, 2, '2025-02-10', 0),
(2, 8, 3, '2025-02-12', 0);

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `room_id` int(11) NOT NULL,
  `room_number` varchar(50) NOT NULL,
  `type` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `room`
--

INSERT INTO `room` (`room_id`, `room_number`, `type`) VALUES
(1, '1', 'test'),
(2, '2', 'consultation'),
(3, '3', 'surgery');

-- --------------------------------------------------------

--
-- Table structure for table `room_serv_compatibility`
--

CREATE TABLE `room_serv_compatibility` (
  `service_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `room_serv_compatibility`
--

INSERT INTO `room_serv_compatibility` (`service_id`, `room_id`) VALUES
(2, 3),
(3, 2);

-- --------------------------------------------------------

--
-- Table structure for table `service`
--

CREATE TABLE `service` (
  `service_id` int(11) NOT NULL,
  `name` tinytext NOT NULL,
  `time` time NOT NULL,
  `specialisation` varchar(100) NOT NULL,
  `referral` tinyint(1) NOT NULL,
  `available` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `service`
--

INSERT INTO `service` (`service_id`, `name`, `time`, `specialisation`, `referral`, `available`) VALUES
(1, 'blood test', '00:30:00', 'apothecary', 0, 1),
(2, 'eye test', '00:45:00', 'optometrist', 1, 1),
(3, 'blood donation', '01:00:00', 'hematology', 0, 1),
(4, 'test', '00:15:00', 'apothecary', 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `upcoming_doc_sche`
--

CREATE TABLE `upcoming_doc_sche` (
  `schedule_id` int(11) NOT NULL,
  `doc_id` int(11) NOT NULL,
  `weekday` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `clock_in` time NOT NULL,
  `clock_out` time NOT NULL,
  `lunch_break` time NOT NULL,
  `firing_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_doctor`
-- (See below for the actual view)
--
CREATE TABLE `view_doctor` (
`doc_id` int(11)
,`worker_id` int(11)
,`name` varchar(50)
,`surname` varchar(50)
,`specialisation` varchar(100)
,`phone_number` varchar(13)
,`email` tinytext
,`doc_log` varchar(50)
,`doc_pass` tinytext
);

-- --------------------------------------------------------

--
-- Table structure for table `view_mat_month_report`
--

CREATE TABLE `view_mat_month_report` (
  `service_id` int(11) NOT NULL,
  `name` tinytext NOT NULL,
  `refferal` tinyint(1) NOT NULL,
  `available` tinyint(1) NOT NULL,
  `times_done` int(11) NOT NULL,
  `percentage` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `view_mat_month_report`
--

INSERT INTO `view_mat_month_report` (`service_id`, `name`, `refferal`, `available`, `times_done`, `percentage`) VALUES
(1, 'blood test', 0, 1, 3, 75),
(2, 'eye test', 1, 1, 1, 25);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_today_app`
-- (See below for the actual view)
--
CREATE TABLE `view_today_app` (
`app_id` int(11)
,`service` tinytext
,`patient_name` varchar(50)
,`patient_surname` varchar(50)
,`patient_email` tinytext
,`doctor_name` varchar(50)
,`doctor_surname` varchar(50)
,`doctor_email` tinytext
,`room_number` varchar(50)
,`time` time(5)
);

-- --------------------------------------------------------

--
-- Table structure for table `worker`
--

CREATE TABLE `worker` (
  `worker_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `surname` varchar(50) NOT NULL,
  `position` varchar(100) NOT NULL,
  `phone_number` varchar(13) NOT NULL,
  `email` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `worker`
--

INSERT INTO `worker` (`worker_id`, `name`, `surname`, `position`, `phone_number`, `email`) VALUES
(1, 'adam', 'test', 'test', '111111111', 'test'),
(2, 'ned', 'kelly', 'sec', '111', '222'),
(3, 'kille', 'kelly', 'doctor', '222', '333'),
(4, 'adam', 'test', 'test', '1', 'test'),
(5, 'andrzej', 'kowalski', 'recepcjonista', '1', 'test'),
(6, 'Jakub', 'rębacz', 'doctor', '1', 'test'),
(7, 'ned', 'kelly', 'doctor', '123123123', 'no_email'),
(8, 'Sarah', 'Connor', 'doctor', '987654321', 'sarah.connor@email.com'),
(9, 'John', 'Doe', 'nurse', '555555555', 'john.doe@email.com'),
(13, 'dad', 'dad', 'doctor', 'dad', 'adad');

-- --------------------------------------------------------

--
-- Structure for view `view_doctor`
--
DROP TABLE IF EXISTS `view_doctor`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_doctor`  AS SELECT `doctor`.`doc_id` AS `doc_id`, `worker`.`worker_id` AS `worker_id`, `worker`.`name` AS `name`, `worker`.`surname` AS `surname`, `doctor`.`specialisation` AS `specialisation`, `worker`.`phone_number` AS `phone_number`, `worker`.`email` AS `email`, `doctor`.`doc_log` AS `doc_log`, `doctor`.`doc_pass` AS `doc_pass` FROM (`worker` join `doctor` on(`worker`.`worker_id` = `doctor`.`worker_id`))  ;

-- --------------------------------------------------------

--
-- Structure for view `view_today_app`
--
DROP TABLE IF EXISTS `view_today_app`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_today_app`  AS SELECT `appointment`.`app_id` AS `app_id`, `service`.`name` AS `service`, `patient`.`name` AS `patient_name`, `patient`.`surname` AS `patient_surname`, `patient`.`patient_email` AS `patient_email`, `worker`.`name` AS `doctor_name`, `worker`.`surname` AS `doctor_surname`, `worker`.`email` AS `doctor_email`, `room`.`room_number` AS `room_number`, `appointment`.`time` AS `time` FROM (((((`appointment` join `patient` on(`appointment`.`patient_id` = `patient`.`patient_id`)) join `doctor` on(`appointment`.`doc_id` = `doctor`.`doc_id`)) join `worker` on(`doctor`.`worker_id` = `worker`.`worker_id`)) join `room` on(`appointment`.`room_id` = `room`.`room_id`)) join `service` on(`appointment`.`service_id` = `service`.`service_id`)) WHERE `appointment`.`date` = curdate() WITH CASCADED CHECK OPTION  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`admin_id`),
  ADD KEY `worker_id` (`worker_id`);

--
-- Indexes for table `appointment`
--
ALTER TABLE `appointment`
  ADD PRIMARY KEY (`app_id`),
  ADD KEY `patient_id` (`patient_id`,`doc_id`,`service_id`,`room_id`),
  ADD KEY `refferal_id` (`refferal_id`),
  ADD KEY `doc_id` (`doc_id`),
  ADD KEY `appointment_ibfk_3` (`service_id`),
  ADD KEY `appointment_ibfk_4` (`room_id`);

--
-- Indexes for table `doctor`
--
ALTER TABLE `doctor`
  ADD PRIMARY KEY (`doc_id`),
  ADD KEY `worker_id` (`worker_id`);

--
-- Indexes for table `doc_leave`
--
ALTER TABLE `doc_leave`
  ADD PRIMARY KEY (`leave_id`),
  ADD KEY `doc_id` (`doc_id`);

--
-- Indexes for table `doc_schedule`
--
ALTER TABLE `doc_schedule`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `doc_id` (`doc_id`);

--
-- Indexes for table `patient`
--
ALTER TABLE `patient`
  ADD PRIMARY KEY (`patient_id`);

--
-- Indexes for table `prescription`
--
ALTER TABLE `prescription`
  ADD PRIMARY KEY (`pres_id`),
  ADD KEY `app_id` (`app_id`);

--
-- Indexes for table `refferal`
--
ALTER TABLE `refferal`
  ADD PRIMARY KEY (`refferal_id`),
  ADD KEY `app_id` (`app_id`,`service_id`),
  ADD KEY `refferal_ibfk_1` (`service_id`);

--
-- Indexes for table `room`
--
ALTER TABLE `room`
  ADD PRIMARY KEY (`room_id`);

--
-- Indexes for table `room_serv_compatibility`
--
ALTER TABLE `room_serv_compatibility`
  ADD PRIMARY KEY (`service_id`,`room_id`),
  ADD KEY `room_serv_compatibility_ibfk_2` (`room_id`);

--
-- Indexes for table `service`
--
ALTER TABLE `service`
  ADD PRIMARY KEY (`service_id`);

--
-- Indexes for table `upcoming_doc_sche`
--
ALTER TABLE `upcoming_doc_sche`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `doc_id` (`doc_id`);

--
-- Indexes for table `worker`
--
ALTER TABLE `worker`
  ADD PRIMARY KEY (`worker_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `app_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `doctor`
--
ALTER TABLE `doctor`
  MODIFY `doc_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `doc_leave`
--
ALTER TABLE `doc_leave`
  MODIFY `leave_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `doc_schedule`
--
ALTER TABLE `doc_schedule`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `patient`
--
ALTER TABLE `patient`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `prescription`
--
ALTER TABLE `prescription`
  MODIFY `pres_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `refferal`
--
ALTER TABLE `refferal`
  MODIFY `refferal_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `room`
--
ALTER TABLE `room`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `service`
--
ALTER TABLE `service`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `worker`
--
ALTER TABLE `worker`
  MODIFY `worker_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admin`
--
ALTER TABLE `admin`
  ADD CONSTRAINT `admin_ibfk_1` FOREIGN KEY (`worker_id`) REFERENCES `worker` (`worker_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `appointment`
--
ALTER TABLE `appointment`
  ADD CONSTRAINT `appointment_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patient` (`patient_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `appointment_ibfk_3` FOREIGN KEY (`service_id`) REFERENCES `service` (`service_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `appointment_ibfk_4` FOREIGN KEY (`room_id`) REFERENCES `room` (`room_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `appointment_ibfk_5` FOREIGN KEY (`doc_id`) REFERENCES `doctor` (`doc_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `appointment_ibfk_6` FOREIGN KEY (`refferal_id`) REFERENCES `refferal` (`refferal_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `doctor`
--
ALTER TABLE `doctor`
  ADD CONSTRAINT `doctor_ibfk_1` FOREIGN KEY (`worker_id`) REFERENCES `worker` (`worker_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `doc_leave`
--
ALTER TABLE `doc_leave`
  ADD CONSTRAINT `doc_leave_ibfk_1` FOREIGN KEY (`doc_id`) REFERENCES `doctor` (`doc_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `doc_schedule`
--
ALTER TABLE `doc_schedule`
  ADD CONSTRAINT `doc_schedule_ibfk_1` FOREIGN KEY (`doc_id`) REFERENCES `doctor` (`doc_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `prescription`
--
ALTER TABLE `prescription`
  ADD CONSTRAINT `prescription_ibfk_1` FOREIGN KEY (`app_id`) REFERENCES `appointment` (`app_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `refferal`
--
ALTER TABLE `refferal`
  ADD CONSTRAINT `refferal_ibfk_1` FOREIGN KEY (`service_id`) REFERENCES `service` (`service_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `refferal_ibfk_2` FOREIGN KEY (`app_id`) REFERENCES `appointment` (`app_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `room_serv_compatibility`
--
ALTER TABLE `room_serv_compatibility`
  ADD CONSTRAINT `room_serv_compatibility_ibfk_1` FOREIGN KEY (`service_id`) REFERENCES `service` (`service_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `room_serv_compatibility_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `room` (`room_id`) ON UPDATE CASCADE;

--
-- Constraints for table `upcoming_doc_sche`
--
ALTER TABLE `upcoming_doc_sche`
  ADD CONSTRAINT `upcoming_doc_sche_ibfk_1` FOREIGN KEY (`doc_id`) REFERENCES `doctor` (`doc_id`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `auto_fill_missing_pres` ON SCHEDULE EVERY 1 DAY STARTS '2024-12-06 02:00:00' ON COMPLETION NOT PRESERVE ENABLE DO call fill_missing_pres(curdate()-1)$$

CREATE DEFINER=`root`@`localhost` EVENT `generate_month_service_report` ON SCHEDULE EVERY 1 MONTH STARTS '2025-02-01 16:05:00' ON COMPLETION PRESERVE ENABLE DO BEGIN
TRUNCATE view_mat_month_report;
INSERT INTO view_mat_month_report
SELECT service.service_id,service.name,service.referral,service.available,count(appointment.app_id)as times_done,(count(appointment.app_id)/
(SELECT COUNT(app_id) FROM appointment WHERE (MONTH(date)-MONTH(curdate())=-1 AND YEAR(date)=YEAR(curdate())) OR(MONTH(date)-MONTH(curdate())=11 AND YEAR(date)-YEAR(curdate())=-1))*100) as percentage FROM service JOIN appointment using(service_id) 
where (MONTH(date)-MONTH(curdate())=-1 AND YEAR(date)=YEAR(curdate())) OR(MONTH(date)-MONTH(curdate())=11 AND YEAR(date)-YEAR(curdate())=-1)
group by service.service_id, name order by available desc,percentage desc;
end$$

CREATE DEFINER=`root`@`localhost` EVENT `deactivate_expired_refferals` ON SCHEDULE EVERY 1 DAY STARTS '2025-01-31 02:00:00' ON COMPLETION PRESERVE ENABLE DO BEGIN
DECLARE id int;
DECLARE list text default "";
DECLARE done int DEFAULT FALSE;
DECLARE cur1 CURSOR FOR SELECT refferal_id FROM refferal where spent=0 AND datediff(curdate(),refferal.suggested_time)>=30;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;
open cur1;
loop1: LOOP
FETCH cur1 into id;
IF done THEN LEAVE loop1; END IF;
SET list=CONCAT(list,",",id);
END LOOP;
UPDATE refferal set spent=1 where refferal_id in(list);
close cur1;
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
