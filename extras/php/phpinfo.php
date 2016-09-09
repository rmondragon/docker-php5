<!doctype html>

<html lang="en">
<head>
    <meta charset="utf-8">

    <title>phpinfo()</title>
    <meta name="description" content="php info">
    <meta name="author" content="rmondragon@gmail.com">

    <!--[if lt IE 9]>
    <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">
</head>

<body>

<div id="wrapper" style="text-align: center">
    <div id="phpmodules" style="text-align: left; display: inline-block;">
        <?php
        // apache_note
        $msg = "<i class=\"fa fa-minus-square-o\"></i> apache_note<br />\n";
        if (function_exists('apache_note')) {
            $msg = "<i class=\"fa fa-check-square-o\"></i> <b>apache_note</b><br />\n";
        }

        echo $msg;

        // geoip
        $msg = "<i class=\"fa fa-minus-square-o\"></i> <b>geoip</b><br />\n";
        if (function_exists('geoip_record_by_name')) {
            $ip_address = '200.121.128.0';
            $ip_country = geoip_record_by_name('200.121.128.0')['country_name'];
            $msg = "<i class=\"fa fa-check-square-o\"></i> <b>geoip</b> - R6 <i class=\"fa fa-heart\"></i> {$ip_country} <br /> \n";
        }

        echo $msg;

        // aerospike
        $msg = "<i class=\"fa fa-minus-square-o\"></i> <b>aerospike</b><br />\n";
        if (extension_loaded('aerospike')) {
            $msg = "<i class=\"fa fa-check-square-o\"></i> <b>aerospike</b> <br /> \n";
        }

        echo $msg;

        // memcached
        $msg = "<i class=\"fa fa-minus-square-o\"></i> <b>memcached</b><br />\n";
        $memcached = new Memcached();
        if ($memcached instanceof Memcached) {
            $msg = "<i class=\"fa fa-check-square-o\"></i> <b>memcached</b> <br /> \n";
        }
        unset($memcached);

        echo $msg;

        // imagick
        $image = new Imagick();
        $msg = "<i class=\"fa fa-minus-square-o\"></i> <b>imagick</b><br />\n";
        if ($image instanceof Imagick) {
            $msg = "<i class=\"fa fa-check-square-o\"></i> <b>imagick</b> <br /> \n";
        }
        unset($image);

        echo $msg;
        ?>
    </div>
    <div id="phash" style="display: inline-block;">
        <?php
        // get image
        $imageUrl = 'http://vignette3.wikia.nocookie.net/ssb/images/d/d8/Bowser%28Clear%29.png';
        $img = file_get_contents($imageUrl);
        if (empty($img)) {
            echo 'Not able to retrieve image.';
            exit;
        }

        // temp image name
        $tempFile = tempnam(sys_get_temp_dir(), 'imghash_');
        if (false === $tempFile) {
            echo 'Not able to create file with unique name.';
            exit;
        }

        // convert to jpg to alleviate any issues with the image file in the format it's in
        file_put_contents($tempFile, $img);
        $imagick = new Imagick($tempFile);
        $converted = $imagick->setImageFormat("jpg");
        if (true === $converted) {
            echo '<img src="data:image/jpg;base64,' . base64_encode($imagick->getImageBlob()) . '" alt="' . $tempFile . '" />';
        } else {
            echo 'Not able to convert to JPG.';
            exit;
        }

        $imagick->writeImage($tempFile);
        // phash
        if (function_exists('ph_dct_imagehash')) {
            $img_hash = ph_dct_imagehash($tempFile);
            echo "<h3>phash: {$img_hash} </h3>";
        }

        // unlink($tempFile);
        ?>
    </div>
</div>
<div id="wrapper" style="text-align: center">
    <div id="phpinfo" style="display: inline-block;">
        <?php
        phpinfo();
        ?>
    </div>
</div>
</body>
</html>