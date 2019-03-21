<?php
    $passphrase = '123456';

    $ctx = stream_context_create();
	stream_context_set_option($ctx, 'ssl', 'local_cert', 'ck-03-08-2018.pem');
    stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

    $errstr = '';
    // Open a connection to the APNS server
    $fp = stream_socket_client(
							   'ssl://gateway.push.apple.com:2195', $err,
                               $errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);

    if (!$fp)
        exit("Failed to connect amarnew: $err $errstr" . PHP_EOL);

        echo 'Connected to APNS' . PHP_EOL;
   $deviceToken = $_REQUEST["deviceToken"];
   $callid = $_REQUEST["callid"];

    $message = "Incoming call from $callid";
    // Create the payload body
//    $body['call-id'] = $callid,
    $body['aps'] = array(
                         'badge' => +1,
                         'title' => CloudCall,
                         'alert' => array(
                         'call-id' => $callid,
                         'loc-key' => $message
                         ),
                         'call-id' => $callid,
                         'loc-key' => $message,
                         'sound' => 'default',
                         'content-available' => 1
                         );
    $payload = json_encode($body);
    // $deviceToken = '39cbd793e727e6f0217fb59582ec565d99a690620ecc0aa65420184938d11d9b';
    //  a843f66f 8ff58966 b458b599 c931ee4a 7002ba3d d18290c7 5e03d837 b1be75eb
    // Build the binary notification
    $msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

    // Send it to the server
    $result = fwrite($fp, $msg, strlen($msg));

    if (!$result)
    echo 'Message not delivered' . PHP_EOL;
    else
    echo 'Message successfully delivered amar' .$message. PHP_EOL;

    // Close the connection to the server
    fclose($fp);
?>
