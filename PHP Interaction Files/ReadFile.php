<?php
    
    //include "connection.php";
    //Change "DatabaseName" to your database's name
    
    
    $POSTData = $_POST;
    
    $password = $POSTData["Password"];
    $username = $POSTData["Username"];
    $SQLQuery = $POSTData["SQLQuery"];
    $con = mysql_connect("localhost", $username, $password) or die;
    mysql_select_db("DatabaseName", $con);
    $result = mysql_query("$SQLQuery", $con);
    $num_rows = mysql_num_rows($result);
    if(mysql_num_rows($result))
    {
        echo '{"Data":[';
        $first = true;
        while($row = mysql_fetch_array($result, MYSQL_ASSOC))
        {
            if($first)
            {
                $first = false;
            }
            else
            {
                echo ',';
            }
            echo json_encode($row);
        }
        echo ']}';
    }
    else
    {
        echo '[No Data]';
    }
    mysql_close($con);
    
    ?>