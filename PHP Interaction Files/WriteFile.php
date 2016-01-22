<?php
    
    //Change "DatabaseName" to your database's name
    
    $POSTData = $_POST;
   	$username = $POSTData["Username"];
    $password = $POSTData["Password"];
    $SQLQuery = $POSTData["SQLQuery"];
    
    $mysqli = new mysqli("localhost", $username, $password, "DatabaseName");
    if ($mysqli->connect_errno)
    {
        echo "Failed to connect to MySQL: (" . $mysqli->connect_errno . ") " . $mysqli->connect_error;
    }
    
    if (!$mysqli->multi_query($SQLQuery))
    {
        echo "Failure: (" . $mysqli->errno . ") " . $mysqli->error;
    }
    else
    {
        echo "Success!";
    }
    ?>