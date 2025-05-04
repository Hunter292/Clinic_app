-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 04, 2025 at 06:59 PM
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
  `patient_email` tinytext NOT NULL,
  `verified` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `prescription`
--

CREATE TABLE `prescription` (
  `pres_id` int(11) NOT NULL,
  `app_id` int(11) NOT NULL,
  `content` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `room_id` int(11) NOT NULL,
  `room_number` varchar(50) NOT NULL,
  `type` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `room_serv_compatibility`
--

CREATE TABLE `room_serv_compatibility` (
  `service_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `appointment`
--
ALTER TABLE `appointment`
  MODIFY `app_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doctor`
--
ALTER TABLE `doctor`
  MODIFY `doc_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doc_leave`
--
ALTER TABLE `doc_leave`
  MODIFY `leave_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doc_schedule`
--
ALTER TABLE `doc_schedule`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `patient`
--
ALTER TABLE `patient`
  MODIFY `patient_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `prescription`
--
ALTER TABLE `prescription`
  MODIFY `pres_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `refferal`
--
ALTER TABLE `refferal`
  MODIFY `refferal_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `room`
--
ALTER TABLE `room`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `service`
--
ALTER TABLE `service`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `upcoming_doc_sche`
--
ALTER TABLE `upcoming_doc_sche`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `worker`
--
ALTER TABLE `worker`
  MODIFY `worker_id` int(11) NOT NULL AUTO_INCREMENT;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
