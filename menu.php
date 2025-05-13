<div id="menu-buff">
    <section id="menu">
        <?php if($type==1){?>
        <a class="linkmenu" href="visits.php">Visits</a>
        <a class="linkmenu" href="make_ap.php">Make appoinment</a>
        <a class="linkmenu" href="refferals.php" >Refferals</a>
        <a class="linkmenu" href="prescriptions.php">Prescriptions</a>
        <?php } if($type==2){?>
            <a class="linkmenu" href="doc_visits.php">Visits</a>
            <a class="linkmenu" href="see_schedule.php">Schedule</a>
            <a class="linkmenu" href="request_time_of.php" >Request time-of</a>
        <?php } if($type==3){?>
        <?php } ?>
            <a class="linkmenu" href="log_out.php">Log out</a>
    </section>
</div>